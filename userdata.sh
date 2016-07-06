#!/bin/bash

sed -i -e 's/Defaults    requiretty//' -e 's/Defaults   !visiblepw//' /etc/sudoers
