require File.dirname(__FILE__) + '/test_helper'
require 'formtastic'

module FormtasticSpecHelper

  def should_have_maxlength_matching_column_limit(method_name, as, column_type)
    semantic_form_for(@new_post) do |builder|
      concat(builder.input(method_name, :as => as))
    end
    @new_post.column_for_attribute(method_name).limit.should == 50
    output_buffer.should have_tag("form li input[@maxlength='#{@new_post.column_for_attribute(method_name).limit}']")
  end

  def should_use_default_text_size_for_columns_longer_than_default(method_name, as, column_type)
    default_size = Formtastic::SemanticFormBuilder.default_text_field_size
    column_limit_larger_than_default = default_size * 2
    @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => column_type, :limit => column_limit_larger_than_default))
    semantic_form_for(@new_post) do |builder|
      concat(builder.input(method_name, :as => as))
    end
    output_buffer.should have_tag("form li input[@size='#{default_size}']")
  end

  def should_use_the_column_size_for_columns_shorter_than_default(method_name, as, column_type)
    default_size = Formtastic::SemanticFormBuilder.default_text_field_size
    column_limit_shorter_than_default = 1
    @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => column_type, :limit => column_limit_shorter_than_default))
    semantic_form_for(@new_post) do |builder|
      concat(builder.input(method_name, :as => as))
    end
    output_buffer.should have_tag("form li input[@size='#{column_limit_shorter_than_default}']")
  end

  def should_use_default_size_for_methods_without_columns(as)
    default_size = Formtastic::SemanticFormBuilder.default_text_field_size
    @new_post.stub!(:column_for_attribute).and_return(nil) # This is the same as not responding to it
    @new_post.stub!(:method_without_column)
    semantic_form_for(@new_post) do |builder|
      concat(builder.input(:method_without_column, :as => as))
    end
    output_buffer.should have_tag("form li input[@size='#{default_size}']")
  end

  def default_input_type(column_type, column_name = :generic_column_name)
    @new_post.stub!(column_name)
    @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => column_type)) unless column_type.nil?
    semantic_form_for(@new_post) do |builder|
      @default_type = builder.send(:default_input_type, @new_post, column_name)
    end
    return @default_type
  end

  def attachment_input_type(method, column_name = :generic_column_name)
    @new_post.stub!(:column_for_attribute).and_return(nil)
    column = mock('column')
    [:file?, :public_filename].each do |test|
      column.stub!(:respond_to?).with(test).and_return(method == test)
    end
    @new_post.should_receive(column_name).and_return(column)
    semantic_form_for(@new_post) do |builder|
      @default_type = builder.send(:default_input_type, @new_post, column_name)
    end
    return @default_type
  end
end

describe 'Formtastic' do

  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::ActiveRecordHelper
  include ActionView::Helpers::RecordIdentificationHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::CaptureHelper
  include ActiveSupport
  include ActionController::PolymorphicRoutes

  include Formtastic::SemanticFormHelper

  attr_accessor :output_buffer

  def protect_against_forgery?; false; end

  before do
    Formtastic::SemanticFormBuilder.label_str_method = :titleize

    @output_buffer = ''

    # Resource-oriented styles like form_for(@post) will expect a path method for the object,
    # so we're defining some here.
    def post_path(o); "/posts/1"; end
    def posts_path; "/posts"; end
    def new_post_path; "/posts/new"; end

    def author_path(o); "/authors/1"; end
    def authors_path; "/authors"; end
    def new_author_path; "/authors/new"; end

    # Sometimes we need some classes
    class Post;
      def id; end
    end
    class Author; end

    @fred = mock('user')
    @fred.stub!(:class).and_return(Author)
    @fred.stub!(:to_label).and_return('Fred Smith')
    @fred.stub!(:login).and_return('fred_smith')
    @fred.stub!(:id).and_return(37)
    @fred.stub!(:new_record?).and_return(false)
    @fred.stub!(:errors).and_return(mock('errors', :on => nil))

    @bob = mock('user')
    @bob.stub!(:class).and_return(Author)
    @bob.stub!(:to_label).and_return('Bob Rock')
    @bob.stub!(:login).and_return('bob')
    @bob.stub!(:id).and_return(42)
    @bob.stub!(:posts).and_return([])
    @bob.stub!(:post_ids).and_return([])
    @bob.stub!(:new_record?).and_return(false)
    @bob.stub!(:errors).and_return(mock('errors', :on => nil))

    Author.stub!(:find).and_return([@fred, @bob])
    Author.stub!(:human_attribute_name).and_return { |column_name| column_name.to_s }
    Author.stub!(:human_name).and_return('Author')
    Author.stub!(:reflect_on_all_validations).and_return([])
    Author.stub!(:reflect_on_association).and_return { |column_name| mock('reflection', :klass => Post, :macro => :has_many) if column_name == :posts }

    # Sometimes we need a mock @post object and some Authors for belongs_to
    @new_post = mock('post')
    @new_post.stub!(:class).and_return(Post)
    @new_post.stub!(:id).and_return(nil)
    @new_post.stub!(:new_record?).and_return(true)
    @new_post.stub!(:errors).and_return(mock('errors', :on => nil))
    @new_post.stub!(:author).and_return(nil)

    @freds_post = mock('post')
    @freds_post.stub!(:class).and_return(Post)
    @freds_post.stub!(:to_label).and_return('Fred Smith')
    @freds_post.stub!(:id).and_return(19)
    @freds_post.stub!(:author).and_return(@fred)
    @freds_post.stub!(:author_id).and_return(@fred.id)
    @freds_post.stub!(:authors).and_return([@fred])
    @freds_post.stub!(:author_ids).and_return([@fred.id])
    @freds_post.stub!(:new_record?).and_return(false)
    @freds_post.stub!(:errors).and_return(mock('errors', :on => nil))
    @fred.stub!(:posts).and_return([@freds_post])
    @fred.stub!(:post_ids).and_return([@freds_post.id])

    Post.stub!(:human_attribute_name).and_return { |column_name| column_name.to_s }
    Post.stub!(:human_name).and_return('Post')
    Post.stub!(:reflect_on_all_validations).and_return([])
    Post.stub!(:reflect_on_association).and_return do |column_name|
      case column_name
      when :author
        mock('reflection', :klass => Author, :macro => :belongs_to)
      when :authors
        mock('reflection', :klass => Author, :macro => :has_and_belongs_to_many)
      end
    end
    Post.stub!(:find).and_return([@freds_post])
  end

  describe 'JustinFrench::Formtastic::SemanticFormBuilder' do
    require 'justin_french/formtastic'
    it 'should be deprecated' do
      ::ActiveSupport::Deprecation.should_receive(:warn).with(/JustinFrench\:\:Formtastic\:\:SemanticFormBuilder/, anything())
      form_for(@new_post, :builder => JustinFrench::Formtastic::SemanticFormBuilder) do |builder|
      end
    end
  end

  describe 'SemanticFormHelper' do

    describe '#semantic_form_for' do

      it 'yields an instance of SemanticFormBuilder' do
        semantic_form_for(:post, Post.new, :url => '/hello') do |builder|
          builder.class.should == Formtastic::SemanticFormBuilder
        end
      end

      it 'adds a class of "formtastic" to the generated form' do
        semantic_form_for(:post, Post.new, :url => '/hello') do |builder|
        end
        output_buffer.should have_tag("form.formtastic")
      end

      it 'adds class matching the object\'s class to the generated form when a symbol is provided' do
        semantic_form_for(:post, Post.new, :url => '/hello') do |builder|
        end
        output_buffer.should have_tag("form.post")
      end

      it 'adds class matching the object\'s class to the generated form when a symbol is provided when an object is provided' do
        semantic_form_for(@new_post) do |builder|
        end
        output_buffer.should have_tag("form.post")
      end

      describe 'allows :html options' do
        before(:each) do
          semantic_form_for(:post, Post.new, :url => '/hello', :html => { :id => "something-special", :class => "something-extra", :multipart => true }) do |builder|
          end
        end

        it 'to add a id of "something-special" to generated form' do
          output_buffer.should have_tag("form#something-special")
        end

        it 'to add a class of "something-extra" to generated form' do
          output_buffer.should have_tag("form.something-extra")
        end

        it 'to add enctype="multipart/form-data"' do
          output_buffer.should have_tag('form[@enctype="multipart/form-data"]')
        end
      end

      it 'can be called with a resource-oriented style' do
        semantic_form_for(@new_post) do |builder|
          builder.object.class.should == Post
          builder.object_name.should == "post"
        end
      end

      it 'can be called with a resource-oriented style with an inline object' do
        semantic_form_for(Post.new) do |builder|
          builder.object.class.should == Post
          builder.object_name.should == "post"
        end
      end

      it 'can be called with a generic style and instance variable' do
        semantic_form_for(:post, @new_post, :url => new_post_path) do |builder|
          builder.object.class.should == Post
          builder.object_name.to_s.should == "post" # TODO: is this forced .to_s a bad assumption somewhere?
        end
      end

      it 'can be called with a generic style and inline object' do
        semantic_form_for(:post, Post.new, :url => new_post_path) do |builder|
          builder.object.class.should == Post
          builder.object_name.to_s.should == "post" # TODO: is this forced .to_s a bad assumption somewhere?
        end
      end

    end

    describe '#semantic_fields_for' do
      it 'yields an instance of SemanticFormBuilder' do
        semantic_fields_for(:post, Post.new, :url => '/hello') do |builder|
          builder.class.should == Formtastic::SemanticFormBuilder
        end
      end
    end

    describe '#semantic_form_remote_for' do
      it 'yields an instance of SemanticFormBuilder' do
        semantic_form_remote_for(:post, Post.new, :url => '/hello') do |builder|
          builder.class.should == Formtastic::SemanticFormBuilder
        end
      end
    end

    describe '#semantic_form_for_remote' do
      it 'yields an instance of SemanticFormBuilder' do
        semantic_form_remote_for(:post, Post.new, :url => '/hello') do |builder|
          builder.class.should == Formtastic::SemanticFormBuilder
        end
      end
    end

  end

  describe 'SemanticFormBuilder' do

    include FormtasticSpecHelper

    describe "@@builder" do
      before do
        @new_post.stub!(:title)
        @new_post.stub!(:body)
        @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))
      end

      it "can be overridden" do

        class CustomFormBuilder < Formtastic::SemanticFormBuilder
          def custom(arg1, arg2, options = {})
            [arg1, arg2, options]
          end
        end

        Formtastic::SemanticFormHelper.builder = CustomFormBuilder

        semantic_form_for(@new_post) do |builder|
          builder.class.should == CustomFormBuilder
          builder.custom("one", "two").should == ["one", "two", {}]
        end
      end

    end

    describe 'Formtastic::SemanticFormBuilder#semantic_fields_for' do
      before do
        @new_post.stub!(:author).and_return(Author.new)
      end

      it 'yields an instance of SemanticFormBuilder' do
        semantic_form_for(@new_post) do |builder|
          builder.semantic_fields_for(:author) do |nested_builder|
            nested_builder.class.should == Formtastic::SemanticFormBuilder
          end
        end
      end

      it 'nests the object name' do
        semantic_form_for(@new_post) do |builder|
          builder.semantic_fields_for(@bob) do |nested_builder|
            nested_builder.object_name.should == 'post[author]'
          end
        end
      end

      it 'should generate html id for li tag properly' do
        @bob.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))
        semantic_form_for(@new_post) do |builder|
          builder.semantic_fields_for(@bob, :index => 1) do |nested_builder|
            concat(nested_builder.inputs :login)
          end
        end
        output_buffer.should have_tag('form fieldset.inputs #post_author_1_login_input')
        output_buffer.should_not have_tag('form fieldset.inputs #post[author]_1_login_input')
      end
    end

    describe '#input' do

      before do
        @new_post.stub!(:title)
        @new_post.stub!(:body)
        @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))
      end

      describe 'with inline order customization' do
        it 'should allow input, hints, errors as order' do
          Formtastic::SemanticFormBuilder.inline_order = [:input, :hints, :errors]

          semantic_form_for(@new_post) do |builder|
            builder.should_receive(:inline_input_for).once.ordered
            builder.should_receive(:inline_hints_for).once.ordered
            builder.should_receive(:inline_errors_for).once.ordered
            concat(builder.input(:title))
          end
        end

        it 'should allow hints, input, errors as order' do
          Formtastic::SemanticFormBuilder.inline_order = [:hints, :input, :errors]

          semantic_form_for(@new_post) do |builder|
            builder.should_receive(:inline_hints_for).once.ordered
            builder.should_receive(:inline_input_for).once.ordered
            builder.should_receive(:inline_errors_for).once.ordered
            concat(builder.input(:title))
          end
        end
      end

      describe 'arguments and options' do

        it 'should require the first argument (the method on form\'s object)' do
            lambda {
            semantic_form_for(@new_post) do |builder|
              concat(builder.input()) # no args passed in at all
            end
          }.should raise_error(ArgumentError)
        end

        it 'should raise a helpful error when the object does not respond to the method supplied in the first argument' do
            semantic_form_for(@new_post) do |builder|
            lambda { builder.input(:method_on_post_that_doesnt_exist) }.should raise_error(NoMethodError, /method_on_post_that_doesnt_exist/)
          end
        end

        describe ':required option' do

          describe 'when true' do

            before do
              @string = Formtastic::SemanticFormBuilder.required_string = " required yo!" # ensure there's something in the string
              @new_post.class.should_not_receive(:reflect_on_all_validations)
            end

            after do
              Formtastic::SemanticFormBuilder.required_string = %{<abbr title="required">*</abbr>}
            end

            it 'should set a "required" class' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :required => true))
              end
              output_buffer.should_not have_tag('form li.optional')
              output_buffer.should have_tag('form li.required')
            end

            it 'should append the "required" string to the label' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :required => true))
              end
              output_buffer.should have_tag('form li.required label', /#{@string}$/)
            end

          end

          describe 'when false' do

            before do
              @string = Formtastic::SemanticFormBuilder.optional_string = " optional yo!" # ensure there's something in the string
              @new_post.class.should_not_receive(:reflect_on_all_validations)
            end

            after do
              Formtastic::SemanticFormBuilder.optional_string = ''
            end

            it 'should set an "optional" class' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :required => false))
              end
              output_buffer.should_not have_tag('form li.required')
              output_buffer.should have_tag('form li.optional')
            end

            it 'should append the "optional" string to the label' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :required => false))
              end
              output_buffer.should have_tag('form li.optional label', /#{@string}$/)
            end

          end

          describe 'when not provided' do

            describe 'and the validation reflection plugin is available' do

              before do
                @new_post.class.stub!(:method_defined?).with(:reflect_on_all_validations).and_return(true)
              end

              describe 'and validates_presence_of was called for the method' do

                before do
                  @new_post.class.should_receive(:reflect_on_all_validations).and_return([
                    mock('MacroReflection', :macro => :validates_presence_of, :name => :title)
                  ])
                end

                it 'should be required' do
                  semantic_form_for(@new_post) do |builder|
                    concat(builder.input(:title))
                  end
                  output_buffer.should have_tag('form li.required')
                  output_buffer.should_not have_tag('form li.optional')
                end

              end

              describe 'and validates_presence_of was not called for the method' do

                before do
                  @new_post.class.should_receive(:reflect_on_all_validations).and_return([])
                end

                it 'should not be required' do
                  semantic_form_for(@new_post) do |builder|
                    concat(builder.input(:title))
                  end
                  output_buffer.should_not have_tag('form li.required')
                  output_buffer.should have_tag('form li.optional')
                end

              end

            end

            describe 'and the validation reflection plugin is not available' do

              it 'should use the default value' do
                Formtastic::SemanticFormBuilder.all_fields_required_by_default.should == true
                Formtastic::SemanticFormBuilder.all_fields_required_by_default = false
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:title))
                end
                output_buffer.should_not have_tag('form li.required')
                output_buffer.should have_tag('form li.optional')
              end

            end

          end

        end

        describe ':as option' do

          describe 'when not provided' do

            it 'should default to a string for methods that don\'t have a column in the database (and can\'t be guessed)' do
              @new_post.stub!(:method_without_a_database_column)
              @new_post.stub!(:column_for_attribute).and_return(nil)
              default_input_type(nil, :method_without_a_database_column).should == :string
            end

            it 'should default to a string for methods on objects that don\'t respond to "column_for_attribute"' do
              @new_post.stub!(:method_without_a_database_column)
#              @new_post.stub!(:column_for_attribute).and_raise(NoMethodError)
              default_input_type(nil, :method_without_a_database_column).should == :string
            end

            it 'should default to :password for methods that don\'t have a column in the database but "password" is in the method name' do
              @new_post.stub!(:password_method_without_a_database_column)
              @new_post.stub!(:column_for_attribute).and_return(nil)
              default_input_type(nil, :password_method_without_a_database_column).should == :password
            end

            it 'should default to :password for methods on objects that don\'t respond to "column_for_attribute" but "password" is in the method name' do
              @new_post.stub!(:password_method_without_a_database_column)
              @new_post.stub!(:column_for_attribute).and_return(nil)
              default_input_type(nil, :password_method_without_a_database_column).should == :password
            end

            it 'should default to :select for column names ending in "_id"' do
              default_input_type(:integer, :user_id).should == :select
              default_input_type(:integer, :section_id).should == :select
            end

            it 'should default to :password for :string column types with "password" in the method name' do
              default_input_type(:string, :password).should == :password
              default_input_type(:string, :hashed_password).should == :password
              default_input_type(:string, :password_hash).should == :password
            end

            it 'should default to :text for :text column types' do
              default_input_type(:text).should == :text
            end

            it 'should default to :date for :date column types' do
              default_input_type(:date).should == :date
            end

            it 'should default to :datetime for :datetime and :timestamp column types' do
              default_input_type(:datetime).should == :datetime
              default_input_type(:timestamp).should == :datetime
            end

            it 'should default to :time for :time column types' do
              default_input_type(:time).should == :time
            end

            it 'should default to :boolean for :boolean column types' do
              default_input_type(:boolean).should == :boolean
            end

            it 'should default to :string for :string column types' do
              default_input_type(:string).should == :string
            end

            it 'should default to :numeric for :integer, :float and :decimal column types' do
              default_input_type(:integer).should == :numeric
              default_input_type(:float).should == :numeric
              default_input_type(:decimal).should == :numeric
            end

            describe 'defaulting to file column' do
              Formtastic::SemanticFormBuilder.file_methods.each do |method|
                it "should default to :file for attributes that respond to ##{method}" do
                  attachment_input_type(method).should == :file
                end
              end
            end

          end

          it 'should call the corresponding input method' do
            [:select, :radio, :date, :datetime, :time, :boolean, :boolean_select].each do |input_style|
              @new_post.stub!(:generic_column_name)
              @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))
              semantic_form_for(@new_post) do |builder|
                builder.should_receive(:"#{input_style}_input").once.and_return("fake HTML output from #input")
                concat(builder.input(:generic_column_name, :as => input_style))
              end
            end

            Formtastic::SemanticFormBuilder::INPUT_MAPPINGS.keys.each do |input_style|
              @new_post.stub!(:generic_column_name)
              @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))
              semantic_form_for(@new_post) do |builder|
                builder.should_receive(:input_simple).once.and_return("fake HTML output from #input")
                concat(builder.input(:generic_column_name, :as => input_style))
              end
            end
          end

        end

        describe ':label option' do

          describe 'when provided' do

            it 'should be passed down to the label tag' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :label => "Kustom"))
              end
              output_buffer.should have_tag("form li label", /Kustom/)
            end

          end

          describe 'when not provided' do
            describe 'when the default is :titleize' do
              before do
                Formtastic::SemanticFormBuilder.label_str_method = :titleize
                @new_post.stub!(:meta_description) # a two word method name
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:meta_description))
                end
              end
              it 'should default the titleized method name, passing it down to the label tag' do
                output_buffer.should have_tag("form li label", /#{'meta_description'.titleize}/)
              end
            end

            describe 'when the default is :humanize' do
              before do
                Formtastic::SemanticFormBuilder.label_str_method = :humanize
                @new_post.stub!(:meta_description) # a two word method name
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:meta_description))
                end
              end
              it 'should default the humanized method name, passing it down to the label tag' do
                output_buffer.should have_tag("form li label", /#{'meta_description'.humanize}/)
              end
            end

            describe 'when the default is :to_s' do
              before do
                Formtastic::SemanticFormBuilder.label_str_method = :to_s
                @new_post.stub!(:meta_description) # a two word method name
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:meta_description))
                end
              end
              it 'should default the humanized method name, passing it down to the label tag' do
                output_buffer.should have_tag("form li label", /meta_description/)
              end
            end
          end

        end

        describe ':hint option' do

          describe 'when provided' do

            it 'should be passed down to the paragraph tag' do
              hint_text = "this is the title of the post"
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title, :hint => hint_text))
              end
              output_buffer.should have_tag("form li p.inline-hints", hint_text)
            end

          end

          describe 'when not provided' do

            it 'should not render a hint paragraph' do
              hint_text = "this is the title of the post"
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title))
              end
              output_buffer.should_not have_tag("form li p.inline-hints")
            end

          end

        end

      end

      describe ':as any type of input' do

        it 'should create a list item for each input' do
          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:title))
            concat(builder.input(:body))
          end
           output_buffer.should have_tag('form li', :count => 2)
        end

        describe 'when there are errors on the object for this method' do

          before do
            @title_errors = ['must not be blank', 'must be longer than 10 characters', 'must be awesome']
            @errors = mock('errors')
            @errors.stub!(:on).with('title').and_return(@title_errors)
            @new_post.stub!(:errors).and_return(@errors)
          end

          it 'should apply an errors class to the list item' do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:title))
            end
            output_buffer.should have_tag('form li.error')
          end

          it 'should not wrap the input with the Rails default error wrapping' do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:title))
            end
            output_buffer.should_not have_tag('div.fieldWithErrors')
          end

          describe 'and the errors will be displayed as a sentence' do

            before do
              Formtastic::SemanticFormBuilder.inline_errors = :sentence
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title))
              end
            end

            it 'should render a paragraph with the errors joined into a sentence' do
              output_buffer.should have_tag('form li.error p.inline-errors', @title_errors.to_sentence)
            end

          end

          describe 'and the errors will be displayed as a list' do

            before do
              Formtastic::SemanticFormBuilder.inline_errors = :list
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title))
              end
            end

            it 'should render an unordered list with the class errors' do
              output_buffer.should have_tag('form li.error ul.errors')
            end

            it 'should include a list element for each of the errors within the unordered list' do
              @title_errors.each do |error|
                output_buffer.should have_tag('form li.error ul.errors li', error)
              end
            end

          end

          describe 'but the errors will not be shown' do

            before do
              Formtastic::SemanticFormBuilder.inline_errors = :none
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:title))
              end
            end

            it 'should not display an error sentence' do
              output_buffer.should_not have_tag('form li.error p.inline-errors')
            end

            it 'should not display an error list' do
              output_buffer.should_not have_tag('form li.error ul.errors')
            end

          end

        end

        describe 'when there are no errors on the object for this method' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:title))
            end
          end

          it 'should not apply an errors class to the list item' do
            output_buffer.should_not have_tag('form li.error')
          end

          it 'should not render a paragraph for the errors' do
            output_buffer.should_not have_tag('form li.error p.inline-errors')
          end

          it 'should not display an error list' do
            output_buffer.should_not have_tag('form li.error ul.errors')
          end

        end

      end

      describe ':as => :string' do

        before do
          @new_post.stub!(:title)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 50))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:title, :as => :string))
          end
        end

        it 'should have a string class on the wrapper' do
          output_buffer.should have_tag('form li.string')
        end

        it 'should have a post_title_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_title_input')
        end

        it 'should generate a label for the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_title"')
          output_buffer.should have_tag('form li label', /Title/)
        end

        it 'should generate a text input' do
          output_buffer.should have_tag('form li input')
          output_buffer.should have_tag('form li input#post_title')
          output_buffer.should have_tag('form li input[@type="text"]')
          output_buffer.should have_tag('form li input[@name="post[title]"]')
        end

        it 'should have a maxlength matching the column limit' do
          should_have_maxlength_matching_column_limit(:title, :string, :string)
        end

        it 'should use default_text_field_size for columns longer than default_text_field_size' do
          should_use_default_text_size_for_columns_longer_than_default(:title, :string, :string)
        end

        it 'should use the column size for columns shorter than default_text_field_size' do
          should_use_the_column_size_for_columns_shorter_than_default(:title, :string, :string)
        end

        it 'should use default_text_field_size for methods without database columns' do
          should_use_default_size_for_methods_without_columns(:string)
        end

        describe "with object that does not respond to 'column_for_attribute'" do
          it "should have a maxlength of default_text_field_size" do
            should_use_default_size_for_methods_without_columns(:string)
          end
        end

      end

      describe 'for belongs_to associations' do

        before do
          @new_post.stub!(:author).and_return(@bob)
          @new_post.stub!(:author_id).and_return(@bob.id)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :integer, :limit => 255))
        end

        describe ':as => :radio' do

          describe 'when using association_id' do

            before do
              # Check for deprecation message
              ::ActiveSupport::Deprecation.should_receive(:warn).with(/association/, anything())
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author_id, :as => :radio))
              end
            end

            it 'should have a radio class on the wrapper' do
              output_buffer.should have_tag('form li.radio')
            end

            it 'should have a post_author_id_input id on the wrapper' do
              output_buffer.should have_tag('form li#post_author_id_input')
            end

            it 'should generate a fieldset and legend containing label text for the input' do
              output_buffer.should have_tag('form li fieldset')
              output_buffer.should have_tag('form li fieldset legend')
              output_buffer.should have_tag('form li fieldset legend', /Author/)
            end

            it 'should generate an ordered list with a list item for each choice' do
              output_buffer.should have_tag('form li fieldset ol')
              output_buffer.should have_tag('form li fieldset ol li', :count => Author.find(:all).size)
            end

            it 'should have one option with a "selected" attribute' do
              output_buffer.should have_tag('form li input[@checked]', :count => 1)
            end

            describe "each choice" do

              it 'should contain a label for the radio input with a nested input and label text' do
                Author.find(:all).each do |author|
                  output_buffer.should have_tag('form li fieldset ol li label')
                  output_buffer.should have_tag('form li fieldset ol li label', /#{author.to_label}/)
                  output_buffer.should have_tag("form li fieldset ol li label[@for='post_author_id_#{author.id}']")
                  output_buffer.should have_tag("form li fieldset ol li label input")
                end
              end

              it "should have a radio input" do
                Author.find(:all).each do |author|
                  output_buffer.should have_tag("form li fieldset ol li label input#post_author_id_#{author.id}")
                  output_buffer.should have_tag("form li fieldset ol li label input[@type='radio']")
                  output_buffer.should have_tag("form li fieldset ol li label input[@value='#{author.id}']")
                  output_buffer.should have_tag("form li fieldset ol li label input[@name='post[author_id]']")
                end
              end

              xit "should mark input as checked if it's the the existing choice" do
                @new_post.author_id.should == @bob.id
                @new_post.author.id.should == @bob.id
                @new_post.author.should == @bob
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:author_id, :as => :radio))
                end

                output_buffer.should have_tag("form li fieldset ol li label input[@checked='checked']")
              end

            end

          end

          describe 'when using association' do

            before do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :radio))
              end
            end

            it 'should have a radio class on the wrapper' do
              output_buffer.should have_tag('form li.radio')
            end

            it 'should have a post_author_id_input id on the wrapper' do
              output_buffer.should have_tag('form li#post_author_input')
            end

            it 'should generate a fieldset and legend containing label text for the input' do
              output_buffer.should have_tag('form li fieldset')
              output_buffer.should have_tag('form li fieldset legend')
              output_buffer.should have_tag('form li fieldset legend', /Author/)
            end

            it 'should generate an ordered list with a list item for each choice' do
              output_buffer.should have_tag('form li fieldset ol')
              output_buffer.should have_tag('form li fieldset ol li', :count => Author.find(:all).size)
            end

            it 'should have one option with a "selected" attribute' do
              output_buffer.should have_tag('form li input[@checked]', :count => 1)
            end

            describe "each choice" do

              it 'should contain a label for the radio input with a nested input and label text' do
                Author.find(:all).each do |author|
                  output_buffer.should have_tag('form li fieldset ol li label')
                  output_buffer.should have_tag('form li fieldset ol li label', /#{author.to_label}/)
                  output_buffer.should have_tag("form li fieldset ol li label[@for='post_author_id_#{author.id}']")
                  output_buffer.should have_tag("form li fieldset ol li label input")
                end
              end

              it "should have a radio input" do
                Author.find(:all).each do |author|
                  output_buffer.should have_tag("form li fieldset ol li label input#post_author_id_#{author.id}")
                  output_buffer.should have_tag("form li fieldset ol li label input[@type='radio']")
                  output_buffer.should have_tag("form li fieldset ol li label input[@value='#{author.id}']")
                  output_buffer.should have_tag("form li fieldset ol li label input[@name='post[author_id]']")
                end
              end

              xit "should mark input as checked if it's the the existing choice" do
                @new_post.author_id.should == @bob.id
                @new_post.author.id.should == @bob.id
                @new_post.author.should == @bob
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:author_id, :as => :radio))
                end

                output_buffer.should have_tag("form li fieldset ol li label input[@checked='checked']")
              end

            end

          end

          describe 'when the :collection option is not provided' do

            it 'should perform a basic find on the parent class' do
              Author.should_receive(:find)
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :radio))
              end
            end

          end

          describe 'when the :collection option is provided' do

            before do
              @authors = Author.find(:all) * 2
              output_buffer.replace '' # clears the output_buffer from the before block, hax!
            end

            it 'should not call find() on the parent class' do
              Author.should_not_receive(:find)
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :radio, :collection => @authors))
              end
            end

            it 'should use the provided collection' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :radio, :collection => @authors))
              end
              output_buffer.should have_tag('form li fieldset ol li', :count => @authors.size)
            end

            describe 'and the :collection is an array of strings' do

              before do
                @new_post.stub!(:category_name).and_return('')
                @categories = [ 'General', 'Design', 'Development' ]
              end

              it 'should use the string as the label text and value for each radio button' do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:category_name, :as => :radio, :collection => @categories))
                end
                @categories.each do |item|
                  output_buffer.should have_tag('form li fieldset ol li label', /#{item}/i)
                  output_buffer.should have_tag('form li fieldset ol li label input[@value='+item+']')
                end
              end

              it 'should generate a sanitized label for attribute' do
                @bob.stub!(:category_name).and_return(@categories)
                semantic_form_for(@new_post) do |builder|
                  builder.semantic_fields_for(@bob) do |bob_builder|
                    concat(bob_builder.input(:category_name, :as => :radio, :collection => @categories))
                  end
                end

                @categories.each do |item|
                  output_buffer.should have_tag("form li fieldset ol li label[@for='post_author_category_name_#{item.downcase}']")
                end
              end

            end

            describe 'and the :collection is a hash of strings' do

              before do
                @new_post.stub!(:category_name).and_return('')
                @categories = { 'General' => 'gen', 'Design' => 'des','Development' => 'dev' }
              end

              it 'should use the key as the label text and the hash value as the value attribute for each radio button' do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:category_name, :as => :radio, :collection => @categories))
                end

                @categories.each do |label, value|
                  output_buffer.should have_tag('form li fieldset ol li label', /#{label}/i)
                  output_buffer.should have_tag('form li fieldset ol li label input[@value='+value+']')
                end
              end

            end

            describe 'and the :collection is an array of arrays' do

              before do
                @new_post.stub!(:category_name).and_return('')
                @categories = { 'General' => 'gen', 'Design' => 'des','Development' => 'dev' }.to_a
              end

              it 'should use the key as the label text and the hash value as the value attribute for each radio button' do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:category_name, :as => :radio, :collection => @categories))
                end

                @categories.each do |label, value|
                  output_buffer.should have_tag('form li fieldset ol li label', /#{label}/i)
                  output_buffer.should have_tag('form li fieldset ol li label input[@value='+value+']')
                end
              end

            end

          end

          describe 'when the :label_method option is provided' do
            before do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :radio, :label_method => :login))
              end
            end

            it 'should have options with text content from the specified method' do
              Author.find(:all).each do |author|
                output_buffer.should have_tag("form li fieldset ol li label", /#{author.login}/)
              end
            end
          end

          describe 'when the :label_method option is not provided' do
            Formtastic::SemanticFormBuilder.collection_label_methods.each do |label_method|
              describe "when the collection objects respond to #{label_method}" do
                before do
                  @fred.stub!(:respond_to?).and_return { |m| m.to_s == label_method }
                  Author.find(:all).each { |a| a.stub!(label_method).and_return('The Label Text') }
                  semantic_form_for(@new_post) do |builder|
                    concat(builder.input(:author, :as => :radio))
                  end
                end

                it "should render the options with #{label_method} as the label" do
                  Author.find(:all).each do |author|
                    output_buffer.should have_tag("form li fieldset ol li label", /The Label Text/)
                  end
                end
              end
            end
          end

        end

        describe ':as => :select' do

          describe 'when using the association method' do

            describe 'for a belongs_to association' do

              before do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:author, :as => :select))
                end
              end

              it 'should have a select class on the wrapper' do
                output_buffer.should have_tag('form li.select')
              end

              it 'should have a post_author_id_input id on the wrapper' do
                output_buffer.should have_tag('form li#post_author_input')
              end

              it 'should have a label inside the wrapper' do
                output_buffer.should have_tag('form li label')
              end

              it 'should have a select inside the wrapper' do
                output_buffer.should have_tag('form li select')
              end

              it 'should not create a multi-select' do
                output_buffer.should_not have_tag('form li select[@multiple]')
              end

              it 'should create a select without size' do
                output_buffer.should_not have_tag('form li select[@size]')
              end

              it 'should have a select option for each Author' do
                output_buffer.should have_tag('form li select option', :count => Author.find(:all).size)
                Author.find(:all).each do |author|
                  output_buffer.should have_tag("form li select option[@value='#{author.id}']", /#{author.to_label}/)
                end
              end

              it 'should have one option with a "selected" attribute' do
                output_buffer.should have_tag('form li select option[@selected]', :count => 1)
              end

            end

            describe 'for a has_many association' do

              before do
                semantic_form_for(@fred) do |builder|
                  concat(builder.input(:posts, :as => :select))
                end
              end

              it 'should have a select class on the wrapper' do
                output_buffer.should have_tag('form li.select')
              end

              it 'should have a post_author_id_input id on the wrapper' do
                output_buffer.should have_tag('form li#author_posts_input')
              end

              it 'should have a label inside the wrapper' do
                output_buffer.should have_tag('form li label')
              end

              it 'should have a select inside the wrapper' do
                output_buffer.should have_tag('form li select')
              end

              it 'should have a multi-select select' do
                output_buffer.should have_tag('form li select[@multiple="multiple"]')
              end

              it 'should have a select option for each Post' do
                output_buffer.should have_tag('form li select option', :count => Post.find(:all).size)
                Post.find(:all).each do |post|
                  output_buffer.should have_tag("form li select option[@value='#{post.id}']", /#{post.to_label}/)
                end
              end

              it 'should have one option with a "selected" attribute' do
                output_buffer.should have_tag('form li select option[@selected]', :count => 1)
              end

            end

            describe 'for a has_and_belongs_to_many association' do

              before do
                semantic_form_for(@freds_post) do |builder|
                  concat(builder.input(:authors, :as => :select))
                end
              end

              it 'should have a select class on the wrapper' do
                output_buffer.should have_tag('form li.select')
              end

              it 'should have a post_author_id_input id on the wrapper' do
                output_buffer.should have_tag('form li#post_authors_input')
              end

              it 'should have a label inside the wrapper' do
                output_buffer.should have_tag('form li label')
              end

              it 'should have a select inside the wrapper' do
                output_buffer.should have_tag('form li select')
              end

              it 'should have a multi-select select' do
                output_buffer.should have_tag('form li select[@multiple="multiple"]')
              end

              it 'should have a select option for each Author' do
                output_buffer.should have_tag('form li select option', :count => Author.find(:all).size)
                Author.find(:all).each do |author|
                  output_buffer.should have_tag("form li select option[@value='#{author.id}']", /#{author.to_label}/)
                end
              end

              it 'should have one option with a "selected" attribute' do
                output_buffer.should have_tag('form li select option[@selected]', :count => 1)
              end

            end

          end

          describe 'when using the association_id method' do

            before do
              ::ActiveSupport::Deprecation.should_receive(:warn).with(/association/, anything())
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author_id, :as => :select))
              end
            end

            it 'should have a select class on the wrapper' do
              output_buffer.should have_tag('form li.select')
            end

            it 'should have a post_author_id_input id on the wrapper' do
              output_buffer.should have_tag('form li#post_author_id_input')
            end

            it 'should have a label inside the wrapper' do
              output_buffer.should have_tag('form li label')
            end

            it 'should have a select inside the wrapper' do
              output_buffer.should have_tag('form li select')
            end

            it 'should have a select option for each Author' do
              output_buffer.should have_tag('form li select option', :count => Author.find(:all).size)
              Author.find(:all).each do |author|
                output_buffer.should have_tag("form li select option[@value='#{author.id}']", /#{author.to_label}/)
              end
            end

            it 'should have one option with a "selected" attribute' do
              output_buffer.should have_tag('form li select option[@selected]', :count => 1)
            end

          end

          describe 'when the :collection option is not provided' do

            it 'should perform a basic find on the parent class' do
              Author.should_receive(:find)
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select))
              end
            end

          end

          describe 'when the :collection option is provided' do

            before do
              @authors = Author.find(:all) * 2
              output_buffer.replace '' # clears the output_buffer from the before block, hax!
            end

            it 'should not call find() on the parent class' do
              Author.should_not_receive(:find)
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select, :collection => @authors))
              end
            end

            it 'should use the provided collection' do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select, :collection => @authors))
              end
              output_buffer.should have_tag('form li select option', :count => @authors.size)
            end

            describe 'and the :collection is an array of strings' do

              before do
                @new_post.stub!(:category_name).and_return('')
                @categories = [ 'General', 'Design', 'Development' ]
              end

              it 'should use the string as the text and value for each option element' do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:category_name, :as => :select, :collection => @categories))
                end
                @categories.each do |item|
                  output_buffer.should have_tag('form li select option[@value='+item+']', item)
                end
              end

            end

            describe 'and the :collection is a hash of strings' do

              before do
                @new_post.stub!(:category_name).and_return('')
                @categories = { 'General' => 'gen', 'Design' => 'des','Development' => 'dev' }
              end

              it 'should use the key as the text and the hash value as the value attribute for each option element' do
                semantic_form_for(@new_post) do |builder|
                  concat(builder.input(:category_name, :as => :select, :collection => @categories))
                end
                @categories.each do |label, value|
                  output_buffer.should have_tag('form li select option[@value='+value+']', label)
                end
              end

            end

          end

          describe 'when :include_blank => true, :prompt => "choose something" is set' do
            before do
              @new_post.stub!(:author_id).and_return(nil)
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select, :include_blank => true, :prompt => "choose author"))
              end
            end

            it 'should have a blank select option' do
              output_buffer.should have_tag("form li select option[@value='']", //)
            end

            it 'should have a select with prompt' do
              output_buffer.should have_tag("form li select option[@value='']", /choose author/)
            end
          end

          describe 'when the :value_method option is provided' do
            before do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select, :value_method => :login))
              end
            end

            it 'should have options with values from specified method' do
              Author.find(:all).each do |author|
                output_buffer.should have_tag("form li select option[@value='#{author.login}']")
              end
            end
          end

          describe 'when the :label_method option is not provided' do
            Formtastic::SemanticFormBuilder.collection_label_methods.each do |label_method|
              describe "when the collection objects respond to #{label_method}" do
                before do
                  @fred.stub!(:respond_to?).and_return { |m| m.to_s == label_method }
                  Author.find(:all).each { |a| a.stub!(label_method).and_return('The Label Text') }
                  semantic_form_for(@new_post) do |builder|
                    concat(builder.input(:author, :as => :select))
                  end
                end

                it "should render the options with #{label_method} as the label" do
                  Author.find(:all).each do |author|
                    output_buffer.should have_tag("form li select option", /The Label Text/)
                  end
                end
              end
            end
          end

          describe 'when the :label_method option is provided' do
            before do
              semantic_form_for(@new_post) do |builder|
                concat(builder.input(:author, :as => :select, :label_method => :login))
              end
            end

            it 'should have options with text content from the specified method' do
              Author.find(:all).each do |author|
                output_buffer.should have_tag("form li select option", /#{author.login}/)
              end
            end
          end

        end
      end

      describe ':as => :password' do

        before do
          @new_post.stub!(:password_hash)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 50))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:password_hash, :as => :password))
          end
        end

        it 'should have a password class on the wrapper' do
          output_buffer.should have_tag('form li.password')
        end

        it 'should have a post_title_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_password_hash_input')
        end

        it 'should generate a label for the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_password_hash"')
          output_buffer.should have_tag('form li label', /Password Hash/)
        end

        it 'should generate a password input' do
          output_buffer.should have_tag('form li input')
          output_buffer.should have_tag('form li input#post_password_hash')
          output_buffer.should have_tag('form li input[@type="password"]')
          output_buffer.should have_tag('form li input[@name="post[password_hash]"]')
        end

        it 'should have a maxlength matching the column limit' do
          should_have_maxlength_matching_column_limit(:password_hash, :password, :string)
        end

        it 'should use default_text_field_size for columns longer than default_text_field_size' do
          should_use_default_text_size_for_columns_longer_than_default(:password_hash, :password, :string)
        end

        it 'should use the column size for columns shorter than default_text_field_size' do
          should_use_the_column_size_for_columns_shorter_than_default(:password_hash, :password, :string)
        end

        it 'should use default_text_field_size for methods without database columns' do
          should_use_default_size_for_methods_without_columns(:password)
        end

        describe "with object that does not respond to 'column_for_attribute'" do
          it "should have a maxlength of default_text_field_size" do
            should_use_default_size_for_methods_without_columns(:string)
          end
        end

      end

      describe ':as => :text' do

        before do
          @new_post.stub!(:body)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :text))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:body, :as => :text))
          end
        end

        it 'should have a text class on the wrapper' do
          output_buffer.should have_tag('form li.text')
        end

        it 'should have a post_title_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_body_input')
        end

        it 'should generate a label for the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_body"')
          output_buffer.should have_tag('form li label', /Body/)
        end

        it 'should generate a text input' do
         output_buffer.should have_tag('form li textarea')
         output_buffer.should have_tag('form li textarea#post_body')
         output_buffer.should have_tag('form li textarea[@name="post[body]"]')
        end

      end

      describe ':as => :date' do

        before do
          @new_post.stub!(:publish_at)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :date))

          semantic_form_for(@new_post) do |@builder|
            concat(@builder.input(:publish_at, :as => :date))
          end
        end

        it 'should have a date class on the wrapper li' do
          output_buffer.should have_tag('form li.date')
        end

        it 'should have a fieldset inside the li wrapper' do
          output_buffer.should have_tag('form li.date fieldset')
        end

        it 'should have a legend containing the label text inside the fieldset' do
          output_buffer.should have_tag('form li.date fieldset legend', /Publish At/)
        end

        it 'should have an ordered list of three items inside the fieldset' do
          output_buffer.should have_tag('form li.date fieldset ol')
          output_buffer.should have_tag('form li.date fieldset ol li', :count => 3)
        end

        it 'should have three labels for year, month and day' do
          output_buffer.should have_tag('form li.date fieldset ol li label', :count => 3)
          output_buffer.should have_tag('form li.date fieldset ol li label', /year/i)
          output_buffer.should have_tag('form li.date fieldset ol li label', /month/i)
          output_buffer.should have_tag('form li.date fieldset ol li label', /day/i)
        end

        it 'should have three selects for year, month and day' do
          output_buffer.should have_tag('form li.date fieldset ol li select', :count => 3)
        end

        describe 'when :include_blank => true is set' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :date, :include_blank => true))
            end
          end

          it 'should have a blank select option' do
            output_buffer.should have_tag("option[@value='']", "")
          end
        end

        describe 'when the locale changes the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:year => 'The Year', :month => 'The Month', :day => 'The Day'}
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :date))
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:year => nil, :month => nil, :day => nil}
          end

          it 'should have translated labels for year, month and day' do
            output_buffer.should have_tag('form li.date fieldset ol li label', /The Year/)
            output_buffer.should have_tag('form li.date fieldset ol li label', /The Month/)
            output_buffer.should have_tag('form li.date fieldset ol li label', /The Day/)
          end
        end
      end

      describe ':as => :datetime' do

        before do
          @new_post.stub!(:publish_at)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :datetime))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:publish_at, :as => :datetime))
          end
        end

        it 'should have a datetime class on the wrapper li' do
          output_buffer.should have_tag('form li.datetime')
        end

        it 'should have a fieldset inside the li wrapper' do
          output_buffer.should have_tag('form li.datetime fieldset')
        end

        it 'should have a legend containing the label text inside the fieldset' do
          output_buffer.should have_tag('form li.datetime fieldset legend', /Publish At/)
        end

        it 'should have an ordered list of five items inside the fieldset' do
          output_buffer.should have_tag('form li.datetime fieldset ol')
          output_buffer.should have_tag('form li.datetime fieldset ol li', :count => 5)
        end

        it 'should have five labels for year, month, day, hour and minute' do
          output_buffer.should have_tag('form li.datetime fieldset ol li label', :count => 5)
          output_buffer.should have_tag('form li.datetime fieldset ol li label', /year/i)
          output_buffer.should have_tag('form li.datetime fieldset ol li label', /month/i)
          output_buffer.should have_tag('form li.datetime fieldset ol li label', /day/i)
          output_buffer.should have_tag('form li.datetime fieldset ol li label', /hour/i)
          output_buffer.should have_tag('form li.datetime fieldset ol li label', /minute/i)
        end

        it 'should have five selects for year, month, day, hour and minute' do
          output_buffer.should have_tag('form li.datetime fieldset ol li select', :count => 5)
        end

        it 'should generate a sanitized label and matching ids for attribute' do
          @bob.stub!(:publish_at)
          @bob.stub!(:column_for_attribute).and_return(mock('column', :type => :datetime))

          semantic_form_for(@new_post) do |builder|
            builder.semantic_fields_for(@bob, :index => 10) do |bob_builder|
              concat(bob_builder.input(:publish_at, :as => :datetime))
            end
          end

          1.upto(5) do |i|
            output_buffer.should have_tag("form li fieldset ol li label[@for='post_author_10_publish_at_#{i}i']")
            output_buffer.should have_tag("form li fieldset ol li #post_author_10_publish_at_#{i}i")
          end
        end

        describe 'when :discard_input => true is set' do
          it 'should use default hidden value equals to 1 when attribute returns nil' do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :datetime, :discard_day => true))
            end

            output_buffer.should have_tag("form li fieldset ol input[@type='hidden'][@value='1']")
          end

          it 'should use default attribute value when it is not nil' do
            @new_post.stub!(:publish_at).and_return(Date.new(2007,12,27))
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :datetime, :discard_day => true))
            end

            output_buffer.should have_tag("form li fieldset ol input[@type='hidden'][@value='27']")
          end
        end

        describe 'when :include_blank => true is set' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :datetime, :include_blank => true))
            end
          end

          it 'should have a blank select option' do
            output_buffer.should have_tag("option[@value='']", "")
          end
        end

        describe 'inputs order' do
          it 'should have a default' do
            semantic_form_for(@new_post) do |builder|
              self.should_receive(:select_year).once.ordered.and_return('')
              self.should_receive(:select_month).once.ordered.and_return('')
              self.should_receive(:select_day).once.ordered.and_return('')
              builder.input(:publish_at, :as => :datetime)
            end
          end

          it 'should be specified with :order option' do
            I18n.backend.store_translations 'en', :date => { :order => [:month, :year, :day] }
            semantic_form_for(@new_post) do |builder|
              self.should_receive(:select_month).once.ordered.and_return('')
              self.should_receive(:select_year).once.ordered.and_return('')
              self.should_receive(:select_day).once.ordered.and_return('')
              builder.input(:publish_at, :as => :datetime)
            end
          end

          it 'should be changed through I18n' do
            semantic_form_for(@new_post) do |builder|
              self.should_receive(:select_day).once.ordered.and_return('')
              self.should_receive(:select_month).once.ordered.and_return('')
              self.should_receive(:select_year).once.ordered.and_return('')
              builder.input(:publish_at, :as => :datetime, :order => [:day, :month, :year])
            end
          end
        end

        describe 'when the locale changes the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {
              :year => 'The Year', :month => 'The Month', :day => 'The Day',
              :hour => 'The Hour', :minute => 'The Minute'
            }
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :datetime))
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {
              :year => nil, :month => nil, :day => nil,
              :hour => nil, :minute => nil
            }
          end

          it 'should have translated labels for year, month, day, hour and minute' do
            output_buffer.should have_tag('form li.datetime fieldset ol li label', /The Year/)
            output_buffer.should have_tag('form li.datetime fieldset ol li label', /The Month/)
            output_buffer.should have_tag('form li.datetime fieldset ol li label', /The Day/)
            output_buffer.should have_tag('form li.datetime fieldset ol li label', /The Hour/)
            output_buffer.should have_tag('form li.datetime fieldset ol li label', /The Minute/)
          end
        end
      end

      describe ':as => :time' do

        before do
          @new_post.stub!(:publish_at)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :time))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:publish_at, :as => :time))
          end
        end

        it 'should have a time class on the wrapper li' do
          output_buffer.should have_tag('form li.time')
        end

        it 'should have a fieldset inside the li wrapper' do
          output_buffer.should have_tag('form li.time fieldset')
        end

        it 'should have a legend containing the label text inside the fieldset' do
          output_buffer.should have_tag('form li.time fieldset legend', /Publish At/)
        end

        it 'should have an ordered list of two items inside the fieldset' do
          output_buffer.should have_tag('form li.time fieldset ol')
          output_buffer.should have_tag('form li.time fieldset ol li', :count => 2)
        end

        it 'should have five labels for hour and minute' do
          output_buffer.should have_tag('form li.time fieldset ol li label', :count => 2)
          output_buffer.should have_tag('form li.time fieldset ol li label', /hour/i)
          output_buffer.should have_tag('form li.time fieldset ol li label', /minute/i)
        end

        it 'should have five selects for hour and minute' do
          output_buffer.should have_tag('form li.time fieldset ol li select', :count => 2)
        end

        describe 'when :include_blank => true is set' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :time, :include_blank => true))
            end
          end

          it 'should have a blank select option' do
            output_buffer.should have_tag("option[@value='']", "")
          end
        end

        describe 'when the locale changes the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:hour => 'The Hour', :minute => 'The Minute'}
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:publish_at, :as => :time))
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:hour => nil, :minute => nil}
          end

          it 'should have translated labels for year, month, day, hour and minute' do
            output_buffer.should have_tag('form li.time fieldset ol li label', /The Hour/)
            output_buffer.should have_tag('form li.time fieldset ol li label', /The Minute/)
          end
        end
      end

      describe ':as => :boolean' do

        before do
          @new_post.stub!(:allow_comments)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:allow_comments, :as => :boolean))
          end
        end

        it 'should have a boolean class on the wrapper' do
          output_buffer.should have_tag('form li.boolean')
        end

        it 'should have a post_allow_comments_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_allow_comments_input')
        end

        it 'should generate a label containing the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_allow_comments"')
          output_buffer.should have_tag('form li label', /Allow Comments/)
          output_buffer.should have_tag('form li label input[@type="checkbox"]')
        end

        it 'should generate a checkbox input' do
          output_buffer.should have_tag('form li label input')
          output_buffer.should have_tag('form li label input#post_allow_comments')
          output_buffer.should have_tag('form li label input[@type="checkbox"]')
          output_buffer.should have_tag('form li label input[@name="post[allow_comments]"]')
        end

      end

      describe ':as => :boolean_radio' do

        before do
          @new_post.stub!(:allow_comments)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:allow_comments, :as => :boolean_radio))
          end
        end

        it 'should have a boolean_radio class on the wrapper' do
          output_buffer.should have_tag('form li.boolean_radio')
        end

        it 'should have a post_allow_comments_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_allow_comments_input')
        end

        it 'should generate a fieldset containing a legend' do
          output_buffer.should have_tag('form li fieldset legend', /Allow Comments/)
        end

        it 'should generate a fieldset containing an ordered list of two items with true and false classes' do
          output_buffer.should have_tag('form li fieldset ol li.true', :count => 1)
          output_buffer.should have_tag('form li fieldset ol li.false', :count => 1)
        end

        it 'should generate a fieldset containing two labels' do
          output_buffer.should have_tag('form li fieldset ol li label', :count => 2)
          output_buffer.should have_tag('form li fieldset ol li label', /Yes$/)
          output_buffer.should have_tag('form li fieldset ol li label', /No$/)
        end

        it 'should generate a fieldset containing two radio inputs' do
          output_buffer.should have_tag('form li fieldset ol li label input[@type="radio"]', :count => 2)
          output_buffer.should have_tag('form li fieldset ol li label input[@value="true"]')
          output_buffer.should have_tag('form li fieldset ol li label input[@value="false"]')
        end

        describe 'when the locale sets the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:yes => 'Absolutely!', :no => 'Never!'}
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_radio))
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:yes => nil, :no => nil}
          end

          it 'should allow translation of the labels' do
            output_buffer.should have_tag('form li fieldset ol li label', /Absolutely\!$/)
            output_buffer.should have_tag('form li fieldset ol li label', /Never\!$/)
          end
        end


        describe 'when the value is nil' do
          before do
            @new_post.stub!(:allow_comments).and_return(nil)
            @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))

            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_radio))
            end
          end

          it 'should not mark either input as checked' do
            output_buffer.should_not have_tag('form li fieldset ol li label input[@checked="checked"]')
          end

        end

        describe 'when the value is true' do
          before do
            @new_post.stub!(:allow_comments).and_return(true)
            @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_radio))
            end
          end
          it 'should mark the true input as checked' do
            output_buffer.should have_tag('form li fieldset ol li label input[@value="true"][@checked="checked"]', :count => 1)
          end
          it 'should not mark the false input as checked' do
            output_buffer.should_not have_tag('form li fieldset ol li label input[@value="false"][@checked="checked"]')
          end
        end

        describe 'when the value is false' do
          before do
            @new_post.stub!(:allow_comments).and_return(false)
            @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_radio))
            end
          end
          it 'should not mark the true input as checked' do
            output_buffer.should_not have_tag('form li fieldset ol li.true label input[@value="true"][@checked="checked"]', :count => 1)
          end
          it 'should mark the false input as checked' do
            output_buffer.should have_tag('form li fieldset ol li.false label input[@value="false"][@checked="checked"]')
          end
        end

        describe 'when :true and :false options are provided' do
          before do
            @new_post.stub!(:allow_comments)
            @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_radio, :true => "Absolutely", :false => "No Way"))
            end
          end
          it 'should pass them down to the input labels' do
            output_buffer.should have_tag('form li fieldset ol li.true label', /Absolutely$/)
            output_buffer.should have_tag('form li fieldset ol li.false label', /No Way$/)
          end
        end
      end

      describe ':as => :boolean_select' do

        before do
          @new_post.stub!(:allow_comments)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :boolean))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:allow_comments, :as => :boolean_select))
          end
        end

        it 'should have a boolean_select class on the wrapper' do
          output_buffer.should have_tag('form li.boolean_select')
        end

        it 'should have a post_allow_comments_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_allow_comments_input')
        end

        it 'should generate a label containing the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_allow_comments"')
          output_buffer.should have_tag('form li label', /Allow Comments/)
        end

        it 'should generate a select box with two options' do
          output_buffer.should have_tag('form li select')
          output_buffer.should have_tag('form li select#post_allow_comments')
          output_buffer.should have_tag('form li select[@name="post[allow_comments]"]')
          output_buffer.should have_tag('form li select#post_allow_comments option', :count => 2)
        end

        describe 'when the locale sets the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:yes => 'Absolutely!', :no => 'Never!'}
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_select))
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:yes => nil, :no => nil}
          end

          it 'should allow translation of the labels' do
            output_buffer.should have_tag('form li select')
            output_buffer.should have_tag('form li select#post_allow_comments')
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="true"]', /Absolutely\!/)
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="false"]', /Never\!/)
          end
        end

        describe 'when the :true and :false options are supplied' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_select, :true => "Yes Please!", :false => "No Thanks!"))
            end
          end

          it 'should use the values as the text for the option tags' do
            output_buffer.should have_tag('form li select')
            output_buffer.should have_tag('form li select#post_allow_comments')
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="true"]', /Yes Please\!/)
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="false"]', /No Thanks\!/)
          end

        end

        describe 'when the :true and :false options are not supplied' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_select))
            end
          end

          it 'should use the default values' do
            output_buffer.should have_tag('form li select')
            output_buffer.should have_tag('form li select#post_allow_comments')
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="true"]', /Yes/)
            output_buffer.should have_tag('form li select#post_allow_comments option[@value="false"]', /No/)
          end

        end

        describe 'when :include_blank => true, :prompt => "choose something" is set' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.input(:allow_comments, :as => :boolean_select, :include_blank => true, :prompt => "choose something"))
            end
          end

          it 'should have a blank select option' do
             output_buffer.should have_tag("form li select option[@value='']", / /)
           end
          it 'should have a select with prompt' do
            output_buffer.should have_tag("form li select option[@value='']", /choose something/)
          end
        end

      end

      describe ':as => :numeric' do

        before do
          @new_post.stub!(:comments_count)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :integer, :limit => 50))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:comments_count, :as => :numeric))
          end
          output_buffer.should have_tag('form li.numeric')
        end

        it 'should have a numeric class on the wrapper' do
          output_buffer.should have_tag("form li.numeric")
        end

        it 'should have a comments_count_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_comments_count_input')
        end

        it 'should generate a label for the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_comments_count"')
          output_buffer.should have_tag('form li label', /Comments Count/)
        end

        it 'should generate a text input' do
          output_buffer.should have_tag('form li input')
          output_buffer.should have_tag('form li input#post_comments_count')
          output_buffer.should have_tag('form li input[@type="text"]')
          output_buffer.should have_tag('form li input[@name="post[comments_count]"]')
        end

        it 'should have a maxlength matching the column limit' do
          should_have_maxlength_matching_column_limit(:comments_count, :numeric, :integer)
        end

        it 'should use default_text_field_size for columns longer than default_text_field_size' do
          should_use_default_text_size_for_columns_longer_than_default(:comments_count, :numeric, :integer)
        end

        it 'should use the column size for columns shorter than default_text_field_size' do
          should_use_the_column_size_for_columns_shorter_than_default(:comments_count, :numeric, :integer)
        end

        it 'should use default_text_field_size for methods without database columns' do
          should_use_default_size_for_methods_without_columns(:numeric)
        end

        describe "with object that does not respond to 'column_for_attribute'" do
          it "should have a maxlength of default_text_field_size" do
            should_use_default_size_for_methods_without_columns(:string)
          end
        end

      end

      describe ':as => :file' do
        before do
          @new_post.stub!(:some_file)
          @new_post.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 50))

          semantic_form_for(@new_post) do |builder|
            concat(builder.input(:some_file, :as => :file))
          end
        end

        it 'should have a file class on the wrapper' do
          output_buffer.should have_tag('form li.file')
        end

        it 'should have a post_some_file_input id on the wrapper' do
          output_buffer.should have_tag('form li#post_some_file_input')
        end

        it 'should generate a label for the input' do
          output_buffer.should have_tag('form li label')
          output_buffer.should have_tag('form li label[@for="post_some_file"')
          output_buffer.should have_tag('form li label', /Some File/)
        end

        it 'should generate a file input' do
          output_buffer.should have_tag('form li input')
          output_buffer.should have_tag('form li input#post_some_file')
          output_buffer.should have_tag('form li input[@type="file"]')
          output_buffer.should have_tag('form li input[@name="post[some_file]"]')
        end
      end

    end

    describe '#inputs' do

      describe 'with a block' do

        describe 'when no options are provided' do
          before do
            output_buffer.replace 'before_builder' # clear the output buffer and sets before_builder
            semantic_form_for(@new_post) do |builder|
              @inputs_output = builder.inputs do
                concat('hello')
              end
            end
          end

          it 'should output just the content wrapped in inputs, not the whole template' do
            output_buffer.should      =~ /before_builder/
            @inputs_output.should_not =~ /before_builder/
          end

          it 'should render a fieldset inside the form, with a class of "inputs"' do
            output_buffer.should have_tag("form fieldset.inputs")
          end

          it 'should render an ol inside the fieldset' do
            output_buffer.should have_tag("form fieldset.inputs ol")
          end

          it 'should render the contents of the block inside the ol' do
            output_buffer.should have_tag("form fieldset.inputs ol", /hello/)
          end

          it 'should not render a legend inside the fieldset' do
            output_buffer.should_not have_tag("form fieldset.inputs legend")
          end
        end

        describe 'when a :for option is provided' do
          it 'should render nested inputs' do
            @bob.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))

            semantic_form_for(@new_post) do |builder|
              builder.inputs :for => [:author, @bob] do |bob_builder|
                concat(bob_builder.input :login)
              end
            end

            output_buffer.should have_tag("form fieldset.inputs #post_author_login")
            output_buffer.should_not have_tag("form fieldset.inputs #author_login")
          end

          it 'should raise an error if :for and block with no argument is given' do
            semantic_form_for(@new_post) do |builder|
              proc {
                builder.inputs(:for => [:author, @bob]) do
                  #
                end
              }.should raise_error(ArgumentError, 'You gave :for option with a block to inputs method, ' <<
                                                  'but the block does not accept any argument.')
            end
          end

          it 'should pass options down to semantic_fields_for' do
            @bob.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))

            semantic_form_for(@new_post) do |builder|
              builder.inputs :for => [:author, @bob], :for_options => { :index => 10 } do |bob_builder|
                concat(bob_builder.input :login)
              end
            end

            output_buffer.should have_tag('form fieldset ol li #post_author_10_login')
          end

          it 'should not add builder as a fieldset attribute tag' do
            semantic_form_for(@new_post) do |builder|
              builder.inputs :for => [:author, @bob], :for_options => { :index => 10 } do |bob_builder|
                concat('input')
              end
            end

            output_buffer.should_not have_tag('fieldset[@builder="Formtastic::SemanticFormHelper"]')
          end
        end

        describe 'when a :name option is provided' do
          before do
            @legend_text = "Advanced options"

            semantic_form_for(@new_post) do |builder|
              builder.inputs :name => @legend_text do
              end
            end
          end

          it 'should render a fieldset inside the form' do
            output_buffer.should have_tag("form fieldset legend", /#{@legend_text}/)
          end
        end

        describe 'when other options are provided' do
          before do
            @id_option = 'advanced'
            @class_option = 'wide'

            semantic_form_for(@new_post) do |builder|
              builder.inputs :id => @id_option, :class => @class_option do
              end
            end
          end

          it 'should pass the options into the fieldset tag as attributes' do
            output_buffer.should have_tag("form fieldset##{@id_option}")
            output_buffer.should have_tag("form fieldset.#{@class_option}")
          end
        end

      end

      describe 'without a block' do

        before do
          Post.stub!(:reflections).and_return({:author => mock('reflection')})
          Post.stub!(:content_columns).and_return([mock('column', :name => 'title'), mock('column', :name => 'body')])
          Author.stub!(:find).and_return([@fred, @bob])

          @new_post.stub!(:title)
          @new_post.stub!(:body)
          @new_post.stub!(:author_id)

          @new_post.stub!(:column_for_attribute).with(:title).and_return(mock('column', :type => :string, :limit => 255))
          @new_post.stub!(:column_for_attribute).with(:body).and_return(mock('column', :type => :text))
          @new_post.stub!(:column_for_attribute).with(:author).and_return(nil)
        end

        describe 'with no args' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.inputs)
            end
          end

          it 'should render a form' do
            output_buffer.should have_tag('form')
          end

          it 'should render a fieldset inside the form' do
            output_buffer.should have_tag('form > fieldset.inputs')
          end

          it 'should not render a legend in the fieldset' do
            output_buffer.should_not have_tag('form > fieldset.inputs > legend')
          end

          it 'should render an ol in the fieldset' do
            output_buffer.should have_tag('form > fieldset.inputs > ol')
          end

          it 'should render a list item in the ol for each column returned by Post.column_names' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li', :count => (Post.content_columns.size + Post.reflections.size))
          end

          it 'should render a string list item for title' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li.string')
          end

          it 'should render a text list item for body' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li.text')
          end

          it 'should render a select list item for author_id' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li.select')
          end
        end

        describe 'with column names as args' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.inputs(:title, :body))
            end
          end

          it 'should render a form with a fieldset containing two list items' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li', :count => 2)
            output_buffer.should have_tag('form > fieldset.inputs > ol > li.string')
            output_buffer.should have_tag('form > fieldset.inputs > ol > li.text')
          end
        end

        describe 'when a :for option is provided' do
          it 'should render nested inputs' do
            @bob.stub!(:column_for_attribute).and_return(mock('column', :type => :string, :limit => 255))

            semantic_form_for(@new_post) do |builder|
              concat(builder.inputs :login, :for => @bob)
            end

            output_buffer.should have_tag("form fieldset.inputs #post_author_login")
            output_buffer.should_not have_tag("form fieldset.inputs #author_login")
          end
        end

        describe 'with column names and an options hash as args' do
          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.inputs(:title, :body, :name => "Legendary Legend Text", :id => "my-id"))
            end
          end

          it 'should render a form with a fieldset containing two list items' do
            output_buffer.should have_tag('form > fieldset.inputs > ol > li', :count => 2)
          end

          it 'should pass the options down to the fieldset' do
            output_buffer.should have_tag('form > fieldset#my-id.inputs')
          end

          it 'should use the special :name option as a text for the legend tag' do
            output_buffer.should have_tag('form > fieldset#my-id.inputs > legend', /Legendary Legend Text/)
          end
        end

      end

    end

    describe '#buttons' do

      describe 'with a block' do
        describe 'when no options are provided' do
          before do
            semantic_form_for(@new_post) do |builder|
              builder.buttons do
                concat('hello')
              end
            end
          end
          it 'should render a fieldset inside the form, with a class of "inputs"' do
            output_buffer.should have_tag("form fieldset.buttons")
          end
          it 'should render an ol inside the fieldset' do
            output_buffer.should have_tag("form fieldset.buttons ol")
          end
          it 'should render the contents of the block inside the ol' do
            output_buffer.should have_tag("form fieldset.buttons ol", /hello/)
          end
          it 'should not render a legend inside the fieldset' do
            output_buffer.should_not have_tag("form fieldset.buttons legend")
          end
        end

        describe 'when a :name option is provided' do
          before do
            @legend_text = "Advanced options"

            semantic_form_for(@new_post) do |builder|
              builder.buttons :name => @legend_text do
              end
            end
          end
          it 'should render a fieldset inside the form' do
            output_buffer.should have_tag("form fieldset legend", /#{@legend_text}/)
          end
        end

        describe 'when other options are provided' do
          before do
            @id_option = 'advanced'
            @class_option = 'wide'

            semantic_form_for(@new_post) do |builder|
              builder.buttons :id => @id_option, :class => @class_option do
              end
            end
          end
          it 'should pass the options into the fieldset tag as attributes' do
            output_buffer.should have_tag("form fieldset##{@id_option}")
            output_buffer.should have_tag("form fieldset.#{@class_option}")
          end
        end

      end

      describe 'without a block' do

        describe 'with no args (default buttons)' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.buttons)
            end
          end

          it 'should render a form' do
            output_buffer.should have_tag('form')
          end

          it 'should render a buttons fieldset inside the form' do
            output_buffer.should have_tag('form fieldset.buttons')
          end

          it 'should not render a legend in the fieldset' do
            output_buffer.should_not have_tag('form fieldset.buttons legend')
          end

          it 'should render an ol in the fieldset' do
            output_buffer.should have_tag('form fieldset.buttons ol')
          end

          it 'should render a list item in the ol for each default button' do
            output_buffer.should have_tag('form fieldset.buttons ol li', :count => 1)
          end

          it 'should render a commit list item for the commit button' do
            output_buffer.should have_tag('form fieldset.buttons ol li.commit')
          end

        end

        describe 'with button names as args' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.buttons(:commit))
            end
          end

          it 'should render a form with a fieldset containing a list item for each button arg' do
            output_buffer.should have_tag('form > fieldset.buttons > ol > li', :count => 1)
            output_buffer.should have_tag('form > fieldset.buttons > ol > li.commit')
          end

        end

        describe 'with button names as args and an options hash' do

          before do
            semantic_form_for(@new_post) do |builder|
              concat(builder.buttons(:commit, :name => "Now click a button", :id => "my-id"))
            end
          end

          it 'should render a form with a fieldset containing a list item for each button arg' do
            output_buffer.should have_tag('form > fieldset.buttons > ol > li', :count => 1)
            output_buffer.should have_tag('form > fieldset.buttons > ol > li.commit', :count => 1)
          end

          it 'should pass the options down to the fieldset' do
            output_buffer.should have_tag('form > fieldset#my-id.buttons')
          end

          it 'should use the special :name option as a text for the legend tag' do
            output_buffer.should have_tag('form > fieldset#my-id.buttons > legend', /Now click a button/)
          end

        end

      end

    end

    describe '#commit_button' do

      describe 'when used on any record' do

        before do
          @new_post.stub!(:new_record?).and_return(false)
          semantic_form_for(@new_post) do |builder|
            concat(builder.commit_button)
          end
        end

        it 'should render a commit li' do
          output_buffer.should have_tag('li.commit')
        end

        it 'should render an input with a type attribute of "submit"' do
          output_buffer.should have_tag('li.commit input[@type="submit"]')
        end

        it 'should render an input with a name attribute of "commit"' do
          output_buffer.should have_tag('li.commit input[@name="commit"]')
        end

      end

      describe 'when used on an existing record' do

        it 'should render an input with a value attribute of "Save Post"' do
          @new_post.stub!(:new_record?).and_return(false)
          semantic_form_for(@new_post) do |builder|
            concat(builder.commit_button)
          end
          output_buffer.should have_tag('li.commit input[@value="Save Post"]')
        end

        describe 'when the locale sets the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:save => 'Save Changes To' }
            @new_post.stub!(:new_record?).and_return(false)
            semantic_form_for(@new_post) do |builder|
              concat(builder.commit_button)
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:save => nil}
          end

          it 'should allow translation of the labels' do
            output_buffer.should have_tag('li.commit input[@value="Save Changes To Post"]')
          end
        end
      end

      describe 'when used on a new record' do

        it 'should render an input with a value attribute of "Create Post"' do
          @new_post.stub!(:new_record?).and_return(true)
          semantic_form_for(@new_post) do |builder|
            concat(builder.commit_button)
          end
          output_buffer.should have_tag('li.commit input[@value="Create Post"]')
        end

        describe 'when the locale sets the label text' do
          before do
            I18n.backend.store_translations 'en', :formtastic => {:create => 'Make' }
            semantic_form_for(@new_post) do |builder|
              concat(builder.commit_button)
            end
          end

          after do
            I18n.backend.store_translations 'en', :formtastic => {:create => nil}
          end

          it 'should allow translation of the labels' do
            output_buffer.should have_tag('li.commit input[@value="Make Post"]')
          end
        end
      end

    end

  end

end
