#!/bin/bash
aztec-cli codegen contracts/slow_tree/target -o contracts/artifacts --ts
aztec-cli codegen contracts/proxy_logic/target -o contracts/artifacts --ts
aztec-cli codegen contracts/proxy/target -o contracts/artifacts --ts
