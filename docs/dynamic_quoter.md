
Variables:

- Reserve X: $R_x$
- Reserve Y: $R_y$
- Oracle Midprice: $P$
- Oracle Price of X: $P_x$
- Oracle Price of Y: $P_y$
- Decimals X: d_x
- Decimals Y: d_y

Oracle mid-price is defined as follows:

$$P = P_x / P_y$$

If we consider that $P_x = \frac{USD_{units}}{X_{units}}$, and same goes for $P_y$, then:

$$
P = P_x / P_y \Leftarrow \frac{ \frac{USD_{units}}{X_{units}} }{ \frac{USD_{units}}{Y_{units}} } \\\\
\Leftarrow \frac{Y_{units}}{X_{units}}
$$

Therefore giving us the standard quotation price:

$$
\frac{Y_{units}}{X_{units}} = \frac{QUOTE}{BASE}
$$

### Swap X to Y:
$$
\Delta y = R_x (1 - e^{\frac{- P \Delta x}{R_x 10^{d_x - d_y}}}) \\\\
$$



### Swap Y to X:
$$
\Delta x = R_x (1 - e^{\frac{- \Delta y 10^{d_x - d_y} }{R_x P}}) \\\\
$$




tests:

- oracle price with fee function never returns amount_out bigger than the bare oracle implementation
- oracle fee function must be monotonically increasing
- test specific points in the fee function, backtested on python
- proptest arbitrarily big trades and prices to see if it results overflows (it shouldn't)



****
TODO: add assert that checks that price is never worst than price given by oracle...


# New Model (Stable Swap Flavor)
For the stable swap version, we want:

Flat Slippage for Small Trades: Near-zero slippage when Δy is small relative to r_y, mimicking stable asset pairs (e.g., USDC/USDT).

Exponential Growth Later: Slippage increases sharply as Δy grows beyond a threshold, retaining your AMM’s aggressive slippage for large trades.
Oracle-Based: Still uses P as the reference price.

No r_x: Maintains the property that pricing depends only on r_y.

Approach
Introduce an amplification parameter A (like Curve’s amplification factor) to control flatness:

- For small trades, the effective price stays close to P.
- For large trades, it transitions to the original exponential behavior.

## Modified Pricing Function

Let's define a new marginal price that flattens initially:

- Original marginal price:
$$p_m(y) = p_0 \cdot \frac{1}{1 - \frac{y}{r_y}}$$
- Stable version: Add a term to reduce sensitivity for small $y$, transitioning to the original form later.

### Proposed marginal price:

$$p_m(y) = p_0 \cdot \left(1 + \frac{\frac{y}{r_y}}{A \left(1 - \frac{y}{r_y}\right)}\right)$$

- $A$: Amplification factor (large $A$ flattens slippage, small $A$ approaches the volatile model).
- $\frac{y}{r_y}$: Fraction of Y swapped.
- $1 - \frac{y}{r_y}$: Remaining Y reserve fraction.

### Total $\Delta x$:

$$\Delta x = \int_{0}^{\Delta y} p_0 \cdot \left(1 + \frac{\frac{y}{r_y}}{A \left(1 - \frac{y}{r_y}\right)}\right) \, dy$$

### Solve the Integral

Let $z = \frac{y}{r_y}$, so $dy = r_y \, dz$, and limits from $y = 0$ to $\Delta y$, or $z = 0$ to $\frac{\Delta y}{r_y}$:

$$
\Delta x = p_0 \int_{0}^{\frac{\Delta y}{r_y}} \left(1 + \frac{z}{A(1-z)}\right) r_y \, dz
$$

$$
= p_0 r_y \int_{0}^{\frac{\Delta y}{r_y}} \left(1 + \frac{z}{A(1-z)}\right) dz
$$

- First term: $\int 1 \, dz = z$.
- Second term: $\int \frac{z}{A(1-z)} \, dz$.

- Substitute $u = 1 - z$, $du = -dz$, $z = 1 - u$, limits from $z = 0$ to $\frac{\Delta y}{r_y}$, or $u = 1$ to $1 - \frac{\Delta y}{r_y}$:
- $\int \frac{z}{A(1-z)} \, dz = \int \frac{1-u}{A u} (-du) = -\frac{1}{A} \int \left(\frac{1}{u} - 1\right) du = -\frac{1}{A} (\ln u - u)$.
- Adjust limits: $-\frac{1}{A} [\ln u - u]_{1}^{1 - \frac{\Delta y}{r_y}} = -\frac{1}{A} \left( \ln \left(1 - \frac{\Delta y}{r_y}\right) - \left(1 - \frac{\Delta y}{r_y}\right) - (\ln 1 - 1) \right)$.

### Full solution:

$$
\Delta x = p_0 r_y \left[ z - \frac{1}{A} (\ln(1-z) + z - 1) \right]_{0}^{\frac{\Delta y}{r_y}}
$$

### Evaluate:

- At $z = \frac{\Delta y}{r_y}$: $\frac{\Delta y}{r_y} - \frac{1}{A} \left( \ln \left(1 - \frac{\Delta y}{r_y}\right) + \frac{\Delta y}{r_y} - 1 \right)$.
- At $z = 0$: $0 - \frac{1}{A} (0 + 0 - 1) = \frac{1}{A}$.

$$
\Delta x = p_0 r_y \left( \frac{\Delta y}{r_y} - \frac{1}{A} \left( \ln \left(1 - \frac{\Delta y}{r_y}\right) + \frac{\Delta y}{r_y} - 1 \right) - \frac{1}{A} \right)
$$

### Simplify:

$$
\Delta x = p_0 r_y \left( \frac{\Delta y}{r_y} - \frac{1}{A} \ln \left(1 - \frac{\Delta y}{r_y}\right) - \frac{1}{A} \frac{\Delta y}{r_y} + \frac{1}{A} - \frac{1}{A} \right)
$$

$$
\Delta x = p_0 r_y \left( \frac{\Delta y}{r_y} \left( 1 - \frac{1}{A} \right) - \frac{1}{A} \ln \left(1 - \frac{\Delta y}{r_y}\right) \right)
$$

### Stable Swap Equation

$$
\Delta x = p_0 r_y \left( \left( 1 - \frac{1}{A} \right) \frac{\Delta y}{r_y} - \frac{1}{A} \ln \left(1 - \frac{\Delta y}{r_y}\right) \right)
$$

### Stable Swap Equation - X2Y

For x2y, the P is upside down, so the equation above is wrong, as in it should be dividing by P. And we have to add the decimals:


$$
\Delta x = \frac{10^{d_x - d_y}}{p_0} r_y \left( \left( 1 - \frac{1}{A} \right) \frac{\Delta y}{r_y} - \frac{1}{A} \ln \left(1 - \frac{\Delta y}{r_y}\right) \right)
$$

$$
\frac{\Delta x \cdot 10^{d_x - d_y}}{r_y \cdot p_0} = \left( \left( 1 - \frac{1}{A} \right) \frac{\Delta y}{r_y} - \frac{1}{A} \ln \left(1 - \frac{\Delta y}{r_y}\right) \right)
$$

let k be:
$$
k = \frac{\Delta x \cdot 10^{d_x - d_y}}{r_y \cdot p_0}
$$

let z be:
$$
z = \frac{\Delta y}{r_y}
$$

We then have to find the root of the equation:
$$
F(z) = \left( 1 - \frac{1}{A} \right) z - \frac{1}{A} \ln \left(1 - z\right) - k
$$

In that what is the value of $z$ such that $F(z) = 0$.

Since we know that: $z = \frac{\Delta y}{r_y}$ and we know that the upper bound for $\Delta y = \Delta x \cdot p_o \cdot \frac{10^{d_y}}{10^{dx}}$.

This is because of the equality holds for a swap at the oracle price:
$$
\frac{\Delta y}{\Delta x} \cdot \frac{10^{d_x}}{10^{d_y}} = \frac{Y_o}{X_o}
$$

where $P_o =  \frac{Y_o}{X_o}$ is the oracle price, which relates a quantity of $Y$ with a quantity of $X$.

In other words, since the swap incurs slippage, the actual delta Y must be lower than the delta Y otherwise received by the oracle price:

$$\Delta y < \Delta x \cdot p_o \cdot \frac{10^{d_y}}{10^{dx}}$$


Both $z$ and $\Delta Y$ are positively related. Therefore, we want to find the upper bound of $z$ such that:

$$
z_U = \frac {\Delta y_o}{r_y}
$$

$$
z_U = \frac{\Delta x \cdot p_o}{r_y} \cdot \frac{10^{d_y}}{10^{d_x}}
$$

It follows the constraint:

$$
z < z_U
$$

### Stable Swap Equation - Y2X
For y2x, the P is multiplying and the decimal adjusment dividing:

$$
\Delta y = \frac{p_0}{10^{d_x - d_y}} r_y \left( \left( 1 - \frac{1}{A} \right) \frac{\Delta x}{r_x} - \frac{1}{A} \ln \left(1 - \frac{\Delta x}{r_x}\right) \right)
$$

$$
\frac{\Delta y \cdot 10^{d_x - d_y}}{r_y \cdot p_0} = \left( \left( 1 - \frac{1}{A} \right) \frac{\Delta x}{r_x} - \frac{1}{A} \ln \left(1 - \frac{\Delta x}{r_x}\right) \right)
$$

let k be:
$$
\frac{\Delta y \cdot 10^{d_x - d_y}}{r_y \cdot p_0}
$$

$$
z = \frac{\Delta x}{r_x}
$$

We then have to find the root of the equation:
$$
F(x) = \left( 1 - \frac{1}{A} \right) z - \frac{1}{A} \ln \left(1 - z\right) - k
$$


In that what is the value of $z$ such that $F(z) = 0$.

Since we know that: $z = \frac{\Delta x}{r_x}$ and we know that the upper bound for $\Delta x = \frac{\Delta y}{p_o} \cdot \frac{10^{d_x}}{10^{dy}}$.

This is because of the equality holds for a swap at the oracle price:
$$
\frac{\Delta x}{\Delta y} \cdot \frac{10^{d_y}}{10^{d_x}} = \frac{X_o}{Y_o}
$$

where $P_o =  \frac{Y_o}{X_o}$ is the oracle price, which relates a quantity of $Y$ with a quantity of $X$.

In other words, since the swap incurs slippage, the actual delta Y must be lower than the delta Y otherwise received by the oracle price:

$$\Delta x < \frac{\Delta y}{p_o} \cdot \frac{10^{d_x}}{10^{d_y}}$$


Both $z$ and $\Delta Y$ are positively related. Therefore, we want to find the upper bound of $z$ such that:

$$
z_U = \frac {\Delta x_o}{r_x}
$$

$$
z_U = \frac{\Delta y}{r_x \cdot p_o} \cdot \frac{10^{d_x}}{10^{d_y}}
$$

It follows the constraint:

$$
z < z_U
$$

