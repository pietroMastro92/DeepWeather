# 0002. Settings stay in the popover

Settings opens inside the menu-bar Glance, not as a system Settings window (`Cmd+,`). A separate window would be a second surface we rejected in ADR 0001. The Settings form scrolls on its own so a long Saved Location list cannot push the popover into the Dock; the Glance header and footer stay put.
