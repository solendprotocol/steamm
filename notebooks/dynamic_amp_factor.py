"""
Dynamic Amplification Factor Based on Volatility

This script implements a dynamic amplification factor (A) for the stable swap formula
based on market volatility. The key ideas are:

1. Calculate volatility using an exponentially weighted moving average (EWMA)
2. Map this volatility to an amplification factor using a sigmoid function
3. Test how this affects swap outcomes in different market conditions
"""

import math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
from datetime import datetime, timedelta


from dynamic_amm import swap_x_to_y_stable, swap_y_to_x_stable, get_slippage


# EWMA Volatility Calculation
# We'll use the formula: σ²t = λ * σ²t-1 + (1-λ) * r²t-1
# λ (lambda) is the decay factor (for now we use : 0.94)
# r²t-1 is the squared return from the previous day


def calculate_ewma_volatility(returns, lambda_decay=0.94, initial_variance=None):
    """
    Calculate the exponentially weighted moving average volatility.

    Parameters:
    - returns: Array of historical returns
    - lambda_decay: Decay factor (default: 0.94)
    - initial_variance: Starting variance value (default: squared first return)

    Returns:
    - Array of variance estimates
    """
    if len(returns) == 0:
        return []

    # Initialize the variance array
    variances = np.zeros(len(returns))

    # Set initial variance
    if initial_variance is None:
        variances[0] = returns[0] ** 2
    else:
        variances[0] = initial_variance

    # Calculate EWMA
    for t in range(1, len(returns)):
        variances[t] = (
            lambda_decay * variances[t - 1] + (1 - lambda_decay) * returns[t - 1] ** 2
        )

    return variances


# Map Volatility to Amplification Factor
# Using the formula: A = Amax - [(Amax - Amin) * normalizedVolatility]
# Where normalizedVolatility is calculated using a sigmoid function:
# normalizedVolatility = 1 / (1 + e^(-10 * (volatility - threshold)))


def normalize_volatility(volatility, threshold=0.02, steepness=10):
    """
    Normalize volatility using a sigmoid function.

    Parameters:
    - volatility: Volatility value
    - threshold: Volatility threshold for transition (default: 0.02 or 2%)
    - steepness: Controls the steepness of the sigmoid (default: 10)

    Returns:
    - Normalized volatility between 0 and 1
    """
    return 1 / (1 + np.exp(-steepness * (volatility - threshold)))


def calculate_dynamic_amp_factor(
    volatility, a_min=1, a_max=100, threshold=0.02, steepness=10
):
    """
    Calculate dynamic amplification factor based on volatility.

    Parameters:
    - volatility: Volatility value (standard deviation)
    - a_min: Minimum amplification factor (default: 1)
    - a_max: Maximum amplification factor (default: 100)
    - threshold: Volatility threshold (default: 0.02 or 2%)
    - steepness: Sigmoid steepness (default: 10)

    Returns:
    - Amplification factor A
    """
    norm_vol = normalize_volatility(volatility, threshold, steepness)
    return a_max - ((a_max - a_min) * norm_vol)


# Visualize the Relationship between Volatility and Amplification Factor

def plot_amp_factor_vs_volatility(a_min=1, a_max=100, threshold=0.02, steepness=10):
    volatilities = np.linspace(0, 0.1, 1000)  # 0% to 10% volatility range
    amp_factors = [
        calculate_dynamic_amp_factor(vol, a_min, a_max, threshold, steepness)
        for vol in volatilities
    ]

    plt.figure(figsize=(10, 6))
    plt.plot(volatilities, amp_factors)
    plt.axvline(x=threshold, color="r", linestyle="--", label=f"Threshold: {threshold}")
    plt.xlabel("Volatility (Standard Deviation)")
    plt.ylabel("Amplification Factor (A)")
    plt.title("Dynamic Amplification Factor vs. Volatility")
    plt.grid(True)
    plt.legend()
    plt.show()


# Simulate Price Data and Calculate Dynamic A


def simulate_price_data(days=365, mu=0, sigma=0.02, price_start=1.0, seed=42):
    """
    Simulate daily price data using geometric Brownian motion.

    Parameters:
    - days: Number of days to simulate
    - mu: Drift parameter (daily)
    - sigma: Volatility parameter (daily)
    - price_start: Starting price
    - seed: Random seed for reproducibility

    Returns:
    - DataFrame with dates, prices, returns, and volatility
    """
    np.random.seed(seed)

    # Generate dates
    start_date = datetime.now() - timedelta(days=days)
    dates = [start_date + timedelta(days=i) for i in range(days)]

    # Generate returns with some periodic volatility changes
    base_returns = np.random.normal(mu, sigma, days)

    # Add some volatility clustering
    volatility_multiplier = np.ones(days)
    for i in range(0, days, 60):  # Change volatility every 60 days
        if i + 20 < days:
            volatility_multiplier[i : i + 20] = np.random.uniform(1.5, 3.0)

    returns = base_returns * volatility_multiplier

    # Calculate prices
    prices = [price_start]
    for r in returns:
        prices.append(prices[-1] * (1 + r))
    prices = prices[:-1]  # Remove the extra price

    # Calculate EWMA volatility
    variances = calculate_ewma_volatility(returns)
    volatility = np.sqrt(variances)  # Convert variance to standard deviation

    # Calculate dynamic amplification factor
    amp_factors = [calculate_dynamic_amp_factor(vol) for vol in volatility]

    # Create DataFrame
    df = pd.DataFrame(
        {
            "date": dates,
            "price": prices,
            "return": returns,
            "volatility": volatility,
            "amp_factor": amp_factors,
        }
    )

    return df


# Visualize Price, Volatility, and Amplification Factor Over Time


def plot_simulation_results(data):
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 10), sharex=True)

    # Plot price
    ax1.plot(data["date"], data["price"])
    ax1.set_ylabel("Price")
    ax1.set_title("Simulated Price")
    ax1.grid(True)

    # Plot volatility
    ax2.plot(data["date"], data["volatility"])
    ax2.set_ylabel("Volatility")
    ax2.set_title("EWMA Volatility")
    ax2.grid(True)

    # Plot amplification factor
    ax3.plot(data["date"], data["amp_factor"])
    ax3.set_ylabel("Amplification Factor (A)")
    ax3.set_xlabel("Date")
    ax3.set_title("Dynamic Amplification Factor")
    ax3.grid(True)

    plt.tight_layout()
    plt.show()


# Test the Impact on Swap Functions
# Compare swaps using static A vs. dynamic A based on recent volatility


def compare_static_vs_dynamic_a(
    data, test_date_index, amount_x=10, reserve_x=1000, reserve_y=1000
):
    # Get data for the test date
    test_row = data.iloc[test_date_index]
    test_date = test_row["date"]
    price = test_row["price"]
    dynamic_a = test_row["amp_factor"]
    volatility = test_row["volatility"]

    # Define price parameters
    price_x = price
    price_y = 1.0  # Assuming this is a stablecoin pair

    # Static A options to compare
    static_a_options = [5, 10, 50, 100]

    # Calculate swaps
    results = []

    # Dynamic A
    dy_dynamic = swap_x_to_y_stable(
        amount_x, reserve_x, reserve_y, price_x, price_y, A=dynamic_a
    )
    slippage_dynamic = get_slippage(amount_x, dy_dynamic, price_x, price_y, 0, 0, "x2y")

    results.append(
        {
            "A_type": "Dynamic",
            "A_value": dynamic_a,
            "amount_y": dy_dynamic,
            "slippage": slippage_dynamic,
        }
    )

    # Static A options
    for static_a in static_a_options:
        dy_static = swap_x_to_y_stable(
            amount_x, reserve_x, reserve_y, price_x, price_y, A=static_a
        )
        slippage_static = get_slippage(
            amount_x, dy_static, price_x, price_y, 0, 0, "x2y"
        )

        results.append(
            {
                "A_type": f"Static ({static_a})",
                "A_value": static_a,
                "amount_y": dy_static,
                "slippage": slippage_static,
            }
        )

    # Create results DataFrame
    results_df = pd.DataFrame(results)

    # Display results
    print(f"Test Date: {test_date}")
    print(f"Price X: {price_x:.4f}")
    print(f"Volatility: {volatility:.4f}")
    print(f"Dynamic A: {dynamic_a:.2f}")
    print("\nSwap Results (Amount X = {}):".format(amount_x))
    print(results_df)

    # Plot slippage comparison
    plt.figure(figsize=(10, 6))
    plt.bar(results_df["A_type"], results_df["slippage"] * 100)
    plt.ylabel("Slippage (%)")
    plt.title(f"Slippage Comparison (Volatility: {volatility:.4f})")
    plt.xticks(rotation=45)
    plt.grid(True, axis="y")
    plt.tight_layout()
    plt.show()

    return results_df


# Analyze Slippage across Different Market Conditions


def test_slippage_across_volatility_range(
    data, num_samples=5, amount_x=50, reserve_x=1000, reserve_y=1000
):
    # Sort the data by volatility
    sorted_data = data.sort_values("volatility")

    # Select samples across volatility range
    indices = np.linspace(0, len(sorted_data) - 1, num_samples).astype(int)
    samples = sorted_data.iloc[indices]

    # Collect results
    results = []

    for idx, row in samples.iterrows():
        price_x = row["price"]
        price_y = 1.0  # Assuming stablecoin pair
        dynamic_a = row["amp_factor"]
        volatility = row["volatility"]

        # Calculate swaps with dynamic A
        dy_dynamic = swap_x_to_y_stable(
            amount_x, reserve_x, reserve_y, price_x, price_y, A=dynamic_a
        )
        slippage_dynamic = get_slippage(
            amount_x, dy_dynamic, price_x, price_y, 0, 0, "x2y"
        )

        # Calculate swaps with static A=10 (default)
        dy_static = swap_x_to_y_stable(
            amount_x, reserve_x, reserve_y, price_x, price_y, A=10
        )
        slippage_static = get_slippage(
            amount_x, dy_static, price_x, price_y, 0, 0, "x2y"
        )

        results.append(
            {
                "volatility": volatility,
                "dynamic_a": dynamic_a,
                "slippage_dynamic": slippage_dynamic * 100,  # Convert to percentage
                "slippage_static": slippage_static * 100,  # Convert to percentage
            }
        )

    # Create DataFrame
    results_df = pd.DataFrame(results)

    # Plot results
    plt.figure(figsize=(12, 6))

    plt.subplot(1, 2, 1)
    plt.plot(
        results_df["volatility"],
        results_df["slippage_dynamic"],
        "o-",
        label="Dynamic A",
    )
    plt.plot(
        results_df["volatility"],
        results_df["slippage_static"],
        "s-",
        label="Static A=10",
    )
    plt.xlabel("Volatility")
    plt.ylabel("Slippage (%)")
    plt.title("Slippage vs. Volatility")
    plt.legend()
    plt.grid(True)

    plt.subplot(1, 2, 2)
    plt.scatter(
        results_df["dynamic_a"],
        results_df["slippage_dynamic"],
        c=results_df["volatility"],
        cmap="viridis",
    )
    plt.colorbar(label="Volatility")
    plt.xlabel("Dynamic A Value")
    plt.ylabel("Slippage (%)")
    plt.title("Slippage vs. Dynamic A")
    plt.grid(True)

    plt.tight_layout()
    plt.show()

    return results_df


# Test different parameters for the volatility normalization and A mapping


def compare_parameters(thresholds=[0.01, 0.02, 0.05], steepness_values=[5, 10, 15]):
    volatilities = np.linspace(0, 0.1, 1000)  # 0% to 10% volatility

    plt.figure(figsize=(12, 8))

    for threshold in thresholds:
        for steepness in steepness_values:
            # Calculate A values
            amp_factors = [
                calculate_dynamic_amp_factor(
                    vol, a_min=1, a_max=100, threshold=threshold, steepness=steepness
                )
                for vol in volatilities
            ]

            # Plot
            plt.plot(
                volatilities,
                amp_factors,
                label=f"Threshold={threshold}, Steepness={steepness}",
            )

    plt.xlabel("Volatility")
    plt.ylabel("Amplification Factor (A)")
    plt.title("Comparison of Different Parameters for Dynamic A")
    plt.grid(True)
    plt.legend()
    plt.show()


if __name__ == "__main__":
    # Simulate data
    print("Simulating price data...")
    sim_data = simulate_price_data()
    print("Data simulation complete.")

    # Visualize the relationship between volatility and amplification factor
    print("\nPlotting amplification factor vs. volatility...")
    plot_amp_factor_vs_volatility()

    # Visualize simulation results
    print("\nPlotting simulation results...")
    plot_simulation_results(sim_data)

    # Test with a high volatility period
    print("\nTesting with high volatility period...")
    high_vol_index = sim_data["volatility"].idxmax()
    compare_static_vs_dynamic_a(sim_data, high_vol_index, amount_x=50)

    # Test with a low volatility period
    print("\nTesting with low volatility period...")
    low_vol_index = sim_data["volatility"].idxmin()
    compare_static_vs_dynamic_a(sim_data, low_vol_index, amount_x=50)

    # Test across volatility range
    print("\nAnalyzing slippage across different market conditions...")
    test_slippage_across_volatility_range(sim_data, num_samples=10)

    # Compare different parameters
    print("\nComparing different parameters for dynamic A...")
    compare_parameters()

    print("\nAnalysis complete. Key findings:")
    print(
        "1. The dynamic A approach adjusts the amplification factor based on recent market volatility"
    )
    print(
        "2. During periods of high volatility, A decreases, leading to higher slippage that better protects the pool"
    )
    print(
        "3. During periods of low volatility, A increases, leading to lower slippage for a better user experience"
    )


# TODO:
# - Test with real market data instead of simulated data
# - Fine-tune the threshold and steepness parameters
# - Implement a minimum update frequency to prevent too frequent changes in A
# - Back-test against historical market events

