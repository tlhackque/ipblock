# IPBLOCK

Quickly (and temporarily) block an IP address

Copyright (C) 2017, 2018, 2019, 2020 Timothe Litt

When your machine is under attack from an unexpected source, the last thing that you want to
do is remember the `iptables` syntax for adding an immediate blocking rule.

`ipblock` addresses this issue.  Simply say  

`ipblock 192.0.2.66`, `ipblock 2001:db8::66`,  or `ipblock evil.example.net`

All packets from that address will be dropped.

`ipblock` only adds a single rule to your `iptables` and/or `ip6tables` rulesets, no
matter how many addresses (up to the ipt_recent limit) are blocked.  This rule is
inserted at the top of the specified chain, thus taking precedence over any other exceptions.

The rule is only added the first time that `ipblock` is run, so your `iptables` rules are not reloaded.

Additional command options allow you to:

 - Remove an address from the block list
 - Remove all addresses from the block list
 - List currently blocked addresses and last seen time
 - Save the current blocked address list as a script
 - Disable the block list (removing the extra `iptables` rule
 - Customize the table name and/or chain used

Options, including the desired chain, should be specified in the configuration file.

`ipblock -h` for complete help

## Installation
Download the latest `Vn.m-Release` tarball using the `tar.gz` link at [GitHub](https://github.com/tlhackque/ipblock/releases).

- Do **not** select the `.zip` file, as it does not preserve file permissions.
- Do **NOT** use the **Clone or download** link on the main `ipblock` page, as it provides a `.zip` file.

Unpack the `tar.gz`:  
    tar -xzf ipblock&lt;n&gt;.&lt;m&gt;-Release.tar.gz

This will create a subdirectory named ipblock-&lt;version&gt;.

`cd` to that directory.

`make install`

This will install ipblock in `/usr/local/bin`, which should be in your `PATH`

A `man` page will be installed in `/usr/local/share/man`.

You can install elsewhere by specifying a prefix, as in:

`make prefix=/opt install`

See `Makefile` for other options.

Select an `iptables` chain and specify it in `ipblock.conf`, which will be in `/etc/default` or `/etc/sysconfig`

To avoid locking yourself out, specify a chain that INPUT calls AFTER guard rules
that protect your local network.  E.g. in your standard rules, start with:

> iptables -N BLOCKED  
> iptables -A -i lo -j ACCEPT  
> iptables -A INPUT -s _mylan_,_trustedpublic_ -j ACCEPT  
> iptables -A INPUT -j BLOCKED

and in `ipblock.conf`

> OPTIONS="-C BLOCKED"

Read the disclaimer before running the `ipblock` command.

## De-installation

If you didn't save the unpacked tarball directory, re-create it following the
directions for Installation.

Then

`cd` to that directory.

`make uninstall`

If you selected a different installation directory, include the prefix, e.g.:

`make prefix=/opt uninstall`

If you are uninstalling due to a defect or concern, feel free to create a
bug report.

## License and Disclaimer
Copyright (c) 2017, 2018, 2019, 2020, 2021, 2023 Timothe Litt

This is free software; the author disclaims all responsibility for its use, reliability and consequences.

The name of the author may not be used to endorse any product, but must be retained in the documentation and code.
Any modifications must be clearly documented and attributed, and are the responsibility of their author.

This notice and the copyright statements must be retained in all copies (complete or partial) of this software and documentation.  See LICENSE for details.

**CAUTION:** No checks are performed on the specified address; you can block systems
on your local network, or even the local host itself.

## Bug reports and suggestions
Please raise bug reports or suggestions [on the issues tracker](http://github.com/tlhackque/ipblock/issues).

Always include `ipblock -V`, `ipblock -L`, `iptables -V`, and `ip6tables -V`.  

If there is any error or warning message, include the full terminal session.

Suggestions and/or praise are also welcome.
