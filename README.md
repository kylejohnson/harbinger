harbinger
=========

A ruby script for cleaning up stale EC2 instances based on tags and age

Requirements
------------
 1. `gem install aws-sdk`
 2. Create a config.yml file in harbinger's directory with your AWS credentials.  If you run harbinger.rb without this file, it'll tell you what to do.
 3. On ruby < 1.9, you'l need to add `require 'rubygems'` before `require 'aws-sdk'` in harbinger.rb.
