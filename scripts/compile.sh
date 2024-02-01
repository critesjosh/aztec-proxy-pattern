#!/bin/bash
cd contracts/slow_tree && aztec-nargo compile --silence-warnings
echo "slow_tree compiled"
cd ../proxy_logic && aztec-nargo compile --silence-warnings
echo "proxy_logic compiled"
cd ../proxy && aztec-nargo compile --silence-warnings
echo "proxy compiled"
