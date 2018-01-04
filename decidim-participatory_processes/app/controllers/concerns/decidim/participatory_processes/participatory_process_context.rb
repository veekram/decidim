# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    # This module, when injected into a controller, ensures there's a
    # Participatory Process available and deducts it from the context.
    module ParticipatoryProcessContext
      def self.extended(base)
        base.class_eval do
          include NeedsParticipatoryProcess

          layout "layouts/decidim/participatory_process"

          before_action do
            view_context.instance_eval do
              extend ParticipatoryProcessHelper
            end

            authorize! :read, current_participatory_process
          end
        end
      end

      def ability_context
        super.merge(current_participatory_process: current_participatory_process)
      end
    end
  end
end
