#
# Cookbook:: lampstack
# Recipe:: default
#
# Copyright:: 2022, The Authors, All Rights Reserved.
include_recipe 'lampstack::packages'
include_recipe 'lampstack::httpd'
include_recipe 'lampstack::mysql'