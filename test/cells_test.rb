# encoding: utf-8
require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), *%w[app cells cells_test_one_cell])

module Some
  class Cell < ::Cell::Base
  end
end

class JustOneViewCell < ::Cell::Base
  def some_state
    render
  end
end

class CellContainedInPlugin < ::Cell::Base
  def some_view
  end
end

class MyTestCell < ::Cell::Base
  def direct_output
    "<h9>this state method doesn't render a template but returns a string, which is great!</h9>"
  end

  def state_with_link_to
    render
  end

  def view_in_local_test_views_dir
    render
  end

  def view_with_explicit_english_translation
    render
  end

  def view_containing_partial
    render
  end

  def view_containing_partial_without_cell_name
    render
  end

  def view_containing_nonexistant_partial
    render
  end

  def view_containing_broken_partial
    render
  end

  def view_with_instance_var
    @instance_variable_one = 'yeah'
    @instance_variable_two = 'wow'
    render
  end

  def missing_view
    render
  end

  def state_with_link_to_function
    render
  end
end

# fixtures for view inheritance -------------------------------
# views are located in cells/test/cells/my_mother_cell/
class MyMotherCell < ::Cell::Base
  def hello
    @message = 'hello, kid!'
    render
  end
  def bye
    @message = 'bye, you!'
    render
  end
end

# views are located in cells/test/cells/my_child_cell/
class MyChildCell < MyMotherCell
  def hello
    @message = 'hello, mom!'
    render
  end
  # view is inherited and located in cells/test/cells/my_mother_cell/bye.html.erb
  def bye
    @message = 'bye, mom!'
    render
  end
end

module ReallyModule
  class NestedCell < ::Cell::Base
    # view: cells/test/cells/really_module/nested_cell/happy_state.html.erb
    def happy_state
      render
    end
  end
end

class CellsTest < ActionController::TestCase
  tests CellsTestController

  ### FIXME:
  # Cell::View.warn_cache_misses = true
  def setup
    super
    MyTestCell.default_template_format = :html
  end

  def test_class_aliasing
    assert_equal Cell::Base, Cells::Cell::Base
  end

  def test_view_paths
    assert_kind_of ActionView::PathSet, Cell::Base.view_paths, "must be a PathSet for proper template caching/reloading (see issue#2)"
  end

  def test_cells_view_paths=
    swap( Cell::Base, :view_paths => ['you', 'are', 'here'])  do
      paths = Cell::Base.view_paths
      assert_kind_of ActionView::PathSet, paths, "must not wipe out the PathSet"
      assert_equal 3, Cell::Base.view_paths.size
      assert_equal %w(you are here), Cell::Base.view_paths
    end
  end

  def test_controller_render_methods
    get :call_render_cell_with_strings  # render_cell("test", "state")
    assert_response :success
    assert_tag :tag => 'h9'

    get :call_render_cell_with_syms
    assert_response :success
    assert_tag :tag => 'h9'

    get :call_render_cell_with_state_view
    assert_select '#view_with_instance_var'
  end

  # test simple rendering cycle -------------------------------------------------

  def test_render_state_which_returns_a_string
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:direct_output)

    assert_kind_of String, c
    assert_selekt c, 'h9'

    #assert_raises (NoMethodError) { cell.render_state("non_existing_state") }
  end

  def test_render_state_with_view_file
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:view_with_instance_var)

    assert_selekt c, '#one', 'yeah'
    assert_selekt c, '#two', 'wow'
  end

  def test_render_state_with_layout
  end

  def test_render_state_with_missing_view
    cell = MyTestCell.new(@controller)
    ### TODO: production <-> development/test context.

    assert_raises ActionView::MissingTemplate do
      c = cell.render_state(:missing_view)
    end
  end

  # test partial rendering ------------------------------------------------------

  # ok
  def test_not_existing_partial
    cell = MyTestCell.new(@controller)

    assert_raises ActionView::TemplateError do
      cell.render_state(:view_containing_nonexistant_partial)
    end
  end

  # ok
  def test_broken_partial
    cell = MyTestCell.new(@controller)

    assert_raises ActionView::TemplateError do
      cell.render_state(:view_containing_broken_partial)
    end
  end

  # ok
  def test_render_state_with_partial
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:view_containing_partial)

    assert_selekt c, '#partialContained > #partial'
  end

  def test_render_state_with_partial_without_cell_name
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:view_containing_partial_without_cell_name)

    assert_selekt c, '#partialContained > #partial'
  end

  # test advanced views (prototype_helper, ...) --------------------------------
  ### TODO: fix CellsTestController to allow rendering views with #link_to_function-
  def dont_test_view_with_link_to_function
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:state_with_link_to_function)

    assert_selekt c, '#partialContained > #partial'
  end

  # test view inheritance ------------------------------------------------------

  def test_possible_paths_for_state
    cell = MyChildCell.new(@controller)
    cell_paths = cell.possible_paths_for_state(:bye)

    assert_equal 'my_child/bye', cell_paths.first
    assert_equal 'my_mother/bye', cell_paths.last
  end

  def test_render_state_on_child_where_child_view_exists
    cell = MyChildCell.new(@controller)
    c = cell.render_state(:hello)

    assert_selekt c, '#childHello', 'hello, mom!'
  end

  def test_render_state_on_child_where_view_is_inherited_from_mother
    cell = MyChildCell.new(@controller)
    # puts '  rendering cell!'
    c = cell.render_state(:bye)

    assert_selekt c, '#motherBye', 'bye, mom!'
  end

  # test Cell::View -------------------------------------------------------------

  def test_find_family_view_for_state
    cell = MyChildCell.new(@controller)
    cells_path = File.join(File.dirname(__FILE__), 'app', 'cells')
    cell_template = cell.find_family_view_for_state(:bye, ::Cell::View.new([cells_path], {}, @controller))

    assert_equal 'my_mother/bye.html.erb', cell_template.path
  end

  ### API test (unit) -----------------------------------------------------------
  def test_cell_name
    cell = CellsTestOneCell.new(@controller)

    assert_equal 'cells_test_one', cell.cell_name
    assert_equal 'cells_test_one', CellsTestOneCell.cell_name
  end

  def test_class_from_cell_name
    assert_equal CellsTestOneCell, ::Cell::Base.class_from_cell_name('cells_test_one')
  end

  def test_default_template_format
    # test getter
    cell = MyTestCell.new(@controller)

    assert_equal :html, ::Cell::Base.default_template_format
    assert_equal :html, cell.class.default_template_format

    # test setter
    MyTestCell.default_template_format = :js

    assert_equal :html, ::Cell::Base.default_template_format
    assert_equal :js, cell.class.default_template_format
  end

  def test_defaultize_render_options_for
    cell = MyTestCell.new(@controller)

    assert_equal ({:template_format => :html, :view => :do_it}),
                  cell.defaultize_render_options_for({}, :do_it)
    assert_equal ({:template_format => :html, :view => :do_it}),
                  cell.defaultize_render_options_for({}, :do_it)
    assert_equal ({:template_format => :js, :view => :do_it}),
                  cell.defaultize_render_options_for({:template_format => :js}, :do_it)
    assert_equal ({:template_format => :html, :layout => :metal, :view => :do_it}),
                  cell.defaultize_render_options_for({:layout => :metal}, :do_it)
    assert_equal ({:template_format => :js, :layout => :metal, :view => :do_it}),
                  cell.defaultize_render_options_for({:layout => :metal, :template_format => :js}, :do_it)
  end

  def test_new_directory_hierarchy
    cell = ReallyModule::NestedCell.new(@controller)
    c = cell.render_state(:happy_state)
    @response.body = c

    assert_select '#happyStateView'
  end

  # Thanks to Fran Pena who made us aware of this bug and contributed a patch.
  def test_i18n_support
    swap I18n, :locale => :en do
      cell = MyTestCell.new(@controller)
      c = cell.render_state(:view_with_explicit_english_translation)

      # the view "view_with_explicit_english_translation.en" exists, check if
      # rails' i18n found it:
      assert_selekt c, '#defaultTranslation', 0
      assert_selekt c, '#explicitEnglishTranslation'
    end
  end

  def test_modified_view_finding_for_testing
    cell = MyTestCell.new(@controller)
    c = cell.render_state(:view_in_local_test_views_dir)

    assert_selekt c, '#localView'
  end

  def test_params_in_a_cell_state
    @controller.params = {:my_param => 'value'}
    cell = TestCell.new(@controller)
    c = cell.render_state(:state_using_params)

    assert_equal 'value', c
  end

  def test_log
    assert_nothing_raised do
      TestCell.new(@controller).log("everything is perfect!")
    end
  end

  ### functional tests: ---------------------------------------------------------

  def test_link_to_in_view
    get :render_state_with_link_to

    assert_response :success
    assert_select 'a', 'bla'
  end
end
