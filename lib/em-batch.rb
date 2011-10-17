# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net) 

require "callback-batch"
require "eventmachine"

##
# Core eventmachine module.
# @see http:///www.eventmachine.com/
#

module EM

    ##
    # Sequencer for running batches upon single object.
    #
    
    class Sequencer < CallbackSequencer
    
        ##
        # Constructor.
        # @param [Object] target  target object
        #
        
        def initialize(target)
            super
            @batch = Batch::new
        end
        
    end
    
    ##
    # Batch of the objects and method names with arguments for runninng 
    # on a series.
    #
    
    class Batch < CallbackBatch
    
        ##
        # Schedules next tick execution.
        # @yield
        #
        
        def schedule_tick(&block)
            EM::next_tick(&block)
        end
        
        ##
        # Schedules next call execution.
        # @yield
        #
        
        def schedule_call(&block)
            EM::next_tick(&block)
        end
            
    end
end