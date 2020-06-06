#!/usr/bin/env ruby

require 'find'
require 'optparse'
require 'json'
require 'yaml'

module Message

    RED    = '31;1m'
    BLUE   = '34;1m'
    GREEN  = '32;1m'
    YELLOW = '33;1m'

    def Message.custom(state, message, color)
        return "\033[#{color}#{state}\033[0m #{message}"
    end

    def Message.info(message)
        return custom('[*]', message, BLUE)
    end

    def Message.success(message)
        return custom('[+]', message, GREEN)
    end

    def Message.error(message)
        return custom('[-]', message, RED)
    end

	def Message.matched(message, color)
		return "\033[#{color}#{message}\033[0m"
	end

end

class Result

    attr_accessor :category

    def initialize(topic, category, element, terms="")
        @topic = topic
        @category = category
        @element = element
		@terms = terms
    end

    def description
        @element['description']
    end

    def data
        @element['data']
    end

    def print_text(colored=true, match_colored=false)
		cat = self.get_category()

		# Description with topic and category colored (or not)
		unless colored
		  message = "#{cat} #{@topic}: #{@element['description']}"
		else
		  message = Message.custom("[#{@topic}]", "#{@element['description']}", Message::YELLOW)
		end

		# Matched terms colored in description
		unless @terms.empty? or !match_colored
		   message.gsub!(/#{@terms}/, Message.matched("#{@terms}", Message::RED))
		end

		# Final display
		puts message
        @element['data'].each do |data|
            puts "- #{data}"
        end
        puts ""
    end

    def get_category
        ret_category = '#'
        category_mapping = {
          'cheats'   => '#',
          'links'    => '*',
          'glossary' => '%'
        }

        begin
          return category_mapping[@category]
        rescue IndexError
          ret_category = '#'
        end

        return ret_category
    end
end

class Docsearch

    def initialize(options)
        @opts = options
        @paths = ENV['DOCSEARCH_PATH'].split(':')
        @results = []
        @env = ENV.keys().map { |e| e if e =~ /^DOCSEARCH_/}.compact
    end

    def yaml_content(path)
        begin
            content = YAML.load(File.read(path))
            return content
        rescue
            return false
        end
    end

    def search(file)
        content = self.yaml_content(file)

        # because we are in a loop fetching files from different locations,
        # we don't want to break the loop by exiting.
        return if content == false

        # if we just want to see the resources path
        if content and @opts[:pwd]
            puts "#{file}"
            return
        end

        # Filters rules
        if @opts[:links]
            content.delete('cheats')
            content.delete('glossary')
        elsif @opts[:cheats]
            content.delete('links')
            content.delete('glossary')
        elsif @opts[:glossary]
            content.delete('cheats')
            content.delete('links')
        end

        content.each do |category, elements|
            elements.each do |element|
                topic = File.basename(file)[0..-6]
                if @opts[:terms]
                    terms = @opts[:terms]
                    if element['description'] =~ /(#{terms})/
                        @results.push(Result.new(topic, category, element, terms))
                    end
                else
                    @results.push(Result.new(topic, category, element))    
                end
            end
        end
              
    end

    def topic?(filename)
        [".yaml"].include? File.extname(filename)
    end

    def topics_inventory
        inventory = {} 

        # Retrieve YAML files for paths
        @paths.each do |path|
            inventory[path] ||= []
            Find.find(path) do |file|
                if self.topic?(file)
                    topic = File.basename(file)[0..-6]
                    inventory[path].push(topic)         
                end
            end
        end
       
        # Display results
        inventory.each do |path, topics|
            puts Message.info(path)
            topics.each do |topic|
                puts "#{topic}"
            end
            puts ""
        end
    end

    def  show_env
        @env.each do |envvar|
            if envvar == "DOCSEARCH_PATH"
              puts Message.info(envvar)
              @paths.each do |path|
                puts "#{path}"
              end
            elsif envvar == "DOCSEARCH_COLORED"
              puts Message.info(envvar)
              color_mode = ENV[envvar].to_i == 1 ? 'enabled' : 'disabled'
              puts "color mode #{color_mode}"
            end
            puts ""
        end
    end

    def dispatcher
        if @opts[:inventory]
            self.topics_inventory
        elsif @opts[:env]
            self.show_env
        elsif @opts[:topic] and not @opts[:terms]
            # display all contents
            @paths.each do |path|
                file = File.join(path, @opts[:topic])
                file = "#{file}.yaml"
                self.search(file)
            end
        elsif @opts[:terms]
            # perform classic search
            @paths.each do |path|
                if @opts[:topic]
                   file = File.join(path, @opts[:topic])
                   file = "#{file}.yaml"
                   self.search(file)
                else
                    # Find terms in all files
                    Find.find(path) do |file|
                        # if we found a file with .yaml extension
                        if self.topic?(file)
                            self.search(file)
                       end
                    end
                end
            end
        end
    end

    def print_results(colored, match_colored)
        if @opts[:json] and @results.length > 0
          res = @results.sort_by {|r| r.category}
          j = {}
          res.each do |r|
            if ! j.keys().include?(r.category)
              j[r.category] = []
            end
            j[r.category] << { 'description': r.description, 'data': r.data }
          end
          puts j.to_json 
          return 
        end

        @results.each do |result|
          result.print_text(colored, match_colored)
        end
    end

end

def main()
    if ! ENV.include?('DOCSEARCH_PATH')
      puts Message.error("You need to declare DOCSEARCH_PATH environment variable.")
      exit 2
    end

    options = { :colored => false, :match_colored => false, :json => false }

    if ENV.include?('DOCSEARCH_COLORED')
      options[:colored] = true
    end

    if ENV.include?('DOCSEARCH_MATCH_COLORED')
      options[:match_colored] = true
    end

    OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [ FILTERS ] -s PATTERN"
        opts.on('-C', '--cheats', 'Restrict search on cheatsheets terms') do |cheats|
            options[:cheats] = cheats
        end
        opts.on('-G', '--glossary', 'Restrict search on glossary terms') do |glossary|
            options[:glossary] = glossary
        end
        opts.on('-L', '--links', 'Restrict search on links terms') do |links|
            options[:links] = links
        end
        opts.on('-e', '--env', 'Show useful DOCSEARCH_* environment variables') do |env|
            options[:env] = true
        end
		opts.on('-c', '--colored', 'Enable colored output') do |nocolor|
			options[:colored] = true
		end
        opts.on('-i', '--inventory', 'List all availabled topics') do |inventory|
            options[:inventory] = true
        end
        opts.on('-j', '--json', 'JSON output') do |jsonformat|
            options[:json] = true
        end
        opts.on('-p', '--pwd', 'Show matched file found') do |path|
            options[:pwd] = true
        end
		opts.on('-m', '--match-colored', 'Enable colored match') do |match_colored|
			options[:match_colored] = true
		end
        opts.on('-s', '--search terms', 'Keyword or term to search') do |terms|
            options[:terms] = terms
        end
        opts.on('-t', '--topic topic', 'Search on a specific topic') do |topic|
            options[:topic] = topic
        end
    end.parse!

    paths = ENV['DOCSEARCH_PATH'].split(':')
    docsearch = Docsearch.new(options)
    docsearch.dispatcher
    docsearch.print_results(options[:colored], options[:match_colored])

end

main


