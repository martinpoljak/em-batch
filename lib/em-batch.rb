# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net) 

require "eventmachine"

##
# Core eventmachine module.
# @see http:///www.eventmachine.com/
#

module EM

    ##
    # Sequencer for running batches upon single object.
    #
    
    class Sequencer
    
        ##
        # Holds the batch object.
        # @return [EM::Batch]
        # 
        
        attr_accessor :batch
        @batch

        ##
        # Holds the target object.
        # @return [Object]
        #         
        
        attr_accessor :target
        @target
        
        ##
        # Constructor.
        # @param [Object] target  target object
        #
        
        def initialize(target)
            @batch = Batch::new
            @target = target
        end
        
        ##
        # Handles missing method calls. Puts them to the 
        # processing batch.
        #
        # @param [Symbol] name  name of the method
        # @param [Array] *args  arguments
        # 
        
        def method_missing(name, *args)
            @batch.put(@target, name, args)
        end
        
        ##
        # Executes the batch.
        # @param [Proc] callback
        #
        
        def execute(&callback)
            @batch.execute(&callback)
        end
        
        alias :"execute!" :execute
    end
    
    ##
    # Batch of the objects and method names with arguments for runninng 
    # on a series.
    #
    
    class Batch
    
        ##
        # Holds the call stack of the ordered calls.
        # @return [Array]  the stack
        #
        
        attr_accessor :stack
        @stack
        
        ##
        # Constructor.
        #
        
        def initialize
            @stack = [ ]
        end
        
        ##
        # Puts call order to the batch. If block given, treat arguments 
        # as its arguments. In otherwise expects object, method name 
        # and arguments array.
        #
        # @param [Array] *args  see above
        # @param [Proc] &block see above
        #
        
        def put(*args, &block)
            if block.nil?
                object, method, args = args
                args = [] if args.nil?
            else
                object = nil
                method = block
            end
                
            @stack << [object, method, args]
        end
        
        ##
        # Wraps object by method call receiver and catches all calls
        # including arguments to the batch.
        # 
        # @param [Object] target  target object
        # @return [EM::Batch::Call]  an calls catcher
        #
        
        def take(target)
            Call::new(self, target)
        end
        
        ##
        # Executes the batch.
        #
        # @param [Proc] callback
        # @yield result of last call
        #

        def execute(&callback)
            caller = nil
            result = nil
        
            iterator = Proc::new do
                object, method, args = @stack.shift
                if object.nil? and method.kind_of? Proc
                    result = method.call(*args, &caller)
                elsif not method.nil?
                    if method == :exec
                        result = object.exec(*args, &caller)
                    else
                        result = object.send(method, *args, &caller)
                    end
                elsif not callback.nil?
                    yield *result
                end
            end
            
            caller = Proc::new do |*res|
                EM::next_tick do
                    result = res
                    iterator.call()
                end
            end
            
            iterator.call()
        end
        
        alias :"execute!" :execute
    end
    
    ##
    # Calls catcher.
    #
    
    class Batch::Call
    
        ##
        # Holds parent batch object.
        # @return [EM::Batch]
        #
        
        attr_reader :batch
        @batch
        
        ##
        # Holds the wrapped object.
        # @return [Object]
        #
        
        attr_accessor :target
        @target
        
        ## 
        # Constructor.
        #
        # @param [EM::Batch] batch  parent batch
        # @param [Object] target  target object for wrap
        #
        
        def initialize(batch, target)
            @batch = batch
            @target = target
        end
        
        ##
        # Missing methods catcher which puts the calls to parent batch.
        #
        # @param [Symbol] name  method name
        # @param [Array] *args  method arguments list
        #
        
        def method_missing(name, *args)
            @batch.put(@target, name, args)
        end
    end
end
