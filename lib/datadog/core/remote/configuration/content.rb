# frozen_string_literal: true

require_relative 'path'

module Datadog
  module Core
    module Remote
      class Configuration
        # Content stores the information associated with a specific Configuration::Path
        class Content
          class << self
            def parse(hash)
              path = Path.parse(hash[:path])
              data = hash[:content]

              new(path: path, data: data)
            end
          end

          attr_reader :path, :data

          def initialize(path:, data:)
            @path = path
            @data = data
          end

          private_class_method :new
        end

        # ContentList stores a list of Conetnt instances
        # It provides convinient methods for finding content base on Configuration::Path and Configuration::Target
        class ContentList < Array
          class << self
            def parse(array)
              new.concat(array.map { |c| Content.parse(c) })
            end
          end

          def find_content(path, target)
            find { |c| c.path.eql?(path) && target.check(c) }
          end

          def [](path)
            find { |c| c.path.eql?(path) }
          end

          def paths
            map(&:path).uniq
          end
        end
      end
    end
  end
end
