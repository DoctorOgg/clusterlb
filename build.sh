#!/usr/bin/env bash
bundle install
gem build clusterlb.gemspec
gem push *.gem && rm -vf *.gem
