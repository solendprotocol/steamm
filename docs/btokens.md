### The impact of BToken Ratios on Stable Swap


The BToken Ratio alters the token amounts as follows:

$$
R_{x} = R_{bx} \cdot BToken Ratio_{x}
$$

$$
R_{y} = R_{by} \cdot BToken Ratio_{y}
$$

Similarly:

$$
\Delta_{x} = \Delta_{bx} \cdot BToken Ratio_{x}
$$

$$
\Delta_{y} = \Delta_{by} \cdot BToken Ratio_{y}
$$

The price impact will be driven by how the BToken Ratios alter the parameter $k$. When $k$ is bigger, the root $z$ is bigger. Therefore the output will be bigger, meaning the slippage is lower. Conversely, when k is smaller, the root $z$ is lower, and therefore the output will be smaller, making the slippage bigger.

$$ k \uparrow \implies z^* \uparrow \implies \Delta_{out} \uparrow \implies Slippage \downarrow$$

and

$$ k \downarrow \implies z^* \downarrow \implies \Delta_{out} \downarrow \implies Slippage \uparrow$$

where
$$ z^* : F(z^*) = 0$$




#### For x2y:

$$
k = \frac{\Delta x \cdot P}{R_y \cdot 10^{d_x - d_y}} = \frac{\Delta_{bx} \cdot BToken Ratio_{x} \cdot P} {R_{by} \cdot BToken Ratio_{y} \cdot 10^{d_x - d_y}}
$$

Meaning that,

$$
BTokenRatio_x > BTokenRatio_y \implies k \uparrow \implies Slippage \downarrow
$$

And:
$$
BTokenRatio_x < BTokenRatio_y \implies k \downarrow \implies Slippage \uparrow
$$


#### For y2x:

delta_in.mul(dec_pow).div(r_x.mul(price_raw))

$$
k = \frac{\Delta y \cdot 10^{d_x - d_y}}{R_x \cdot P} = \frac{\Delta_{by} \cdot BToken Ratio_{y} \cdot 10^{d_x - d_y}}{R_{bx} \cdot BToken Ratio_{x} \cdot P}
$$

Meaning that,

$$
BTokenRatio_y > BTokenRatio_x \implies k \uparrow \implies Slippage \downarrow
$$

And:
$$
BTokenRatio_y < BTokenRatio_x \implies k \downarrow \implies Slippage \uparrow
$$

### Conclusion

The following relationship holds:

$$
BTokenRatio_{in} > BTokenRatio_{out} \implies Slippage \downarrow
$$

And:
$$
BTokenRatio_{in} < BTokenRatio_{out} \implies Slippage \uparrow
$$