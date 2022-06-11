# [TF2] Explosion Sound Fix

This plugin aims to fix the nasty flamethrower looping sound that gets played after a rocket explodes.

# Explanation

Whenever an explosion happens, the game checks the definition index of the weapon that "launched" the rocket for custom replacement sounds.

Unfortunately, the sound type that gets played by default is [`SPECIAL1`](https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/weapon_parse.h), which is replaced for most of the flamethrowers (except stock) with the looping burn sound.

You can hear the sound yourself by going in a dodgeball server that doesn't have a fix for this issue or by deflecting a sentry rocket with a flamethrower other than stock. The latter is caused by sentry rockets having their `m_hOriginalLauncher` netprop set to `-1`, which gets replaced on the first deflect.

What this plugin does is check a list of weapon definition indexes and replaces them with the stock flamethrower's index.

# References

1.  [Rocket projectile code](https://github.com/lua9520/source-engine-2018-hl2_src/blob/master/game/shared/tf/tf_weaponbase_rocket.cpp) & [Explosion FX code](https://github.com/lua9520/source-engine-2018-hl2_src/blob/master/game/client/tf/tf_fx_explosions.cpp)
2.  [An already existing fix done by Nanochip](https://gitlab.com/nanochip/fixfireloop/-/blob/master/scripting/fixfireloop.sp)
    
    Nanochip's fix sets the definition index to -1, thus fixing the sound; but it also blocks all explosions from occuring.
