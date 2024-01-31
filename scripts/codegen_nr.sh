#!/bin/bash
aztec-cli codegen contracts/proxy_storage/target -o contracts/proxy_logic/src --nr
aztec-cli codegen contracts/proxy_logic/target -o contracts/proxy/src --nr
