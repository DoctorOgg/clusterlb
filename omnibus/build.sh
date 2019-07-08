#!/usr/bin/env bash
rm -vf pkg/*rpm*
bundle install --binstubs
bin/omnibus build clusterlb
