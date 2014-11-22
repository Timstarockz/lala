#
# postman.rb
# by Tim :D
#

require "json"
require 'pry'

require_relative "ext.rb"

class Postman
  
  attr_accessor :status
  
  def initialize(hash)
    
    self.status = hash
    status_box = {}
    cs = []
    
    if File.exist?("status_box.json") #add new status
      file = File.read("status_box.json")
      status_box = JSON.parse(file, :quirks_mode => true)
      cs = status_box["statuses"]
      cs.insert(0,hash)
      newone = {
        statuses: cs
      }
      
      File.open("status_box.json","w") do |f|
        f.write(newone.to_json)
      end
    else
      array = [hash]
      first = {
        statuses: array
      }
      
      File.open("status_box.json","w") do |f|
        f.write(first.to_json)
      end
    end
  end
  
  def to_s
    self.status.to_json
  end
  
  def mailHash(hash)
  end
end