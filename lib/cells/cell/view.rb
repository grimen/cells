# encoding: utf-8

module Cells
  module Cell
    class View < ::ActionView::Base

      attr_accessor :cell
      alias_method :render_for, :render

      # Tries to find the passed template in view_paths. Returns the view on success-
      # otherwise it will throw an ActionView::MissingTemplate exception.
      def try_picking_template_for_path(template_path)
        self.view_paths.find_template(template_path, self.template_format)
      end

      # Render cell view.
      ### TODO: this should just be a thin helper.
      ### TODO: delegate dynamically:
      ### TODO: we have to find out if this is a call to the cells #render method, or to the rails
      ###       method (e.g. when rendering a layout).
      def render(options = {}, local_assigns = {}, &block)
        if options[:view]
          self.cell.render_view_for(options, options[:view])
        else
          # rails compatibility we should get rid of: adds the cell name to the partial name.
          options[:partial] = self.expand_view_path(options[:partial]) if options[:partial]
          super(options, local_assigns, &block)
        end
      end

      def expand_view_path(path)
        (path && path.include?(File::SEPARATOR)) ? path : File.join("#{cell.cell_name}", "#{path}")
      end

      # this prevents cell ivars from being overwritten by same-named
      # controller ivars.
      # we'll hopefully get a cleaner way, or an API, to handle this in rails 3.
      def _copy_ivars_from_controller #:nodoc:
        if @controller
          variables = @controller.instance_variable_names
          variables -= @controller.protected_instance_variables if @controller.respond_to?(:protected_instance_variables)
          variables -= self.assigns.keys.collect { |key| "@#{key}" } # cell ivars override controller ivars.
          variables.each { |name| self.instance_variable_set(name, @controller.instance_variable_get(name)) }
        end
      end

    end
  end
end
