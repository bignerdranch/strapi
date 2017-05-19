# define classes retrieved by constant name
class WidgetQuery
  def initialize(*)
  end
end

class WidgetFilter
end

describe Strapi::ControllerMethods do
  let(:controller) {
    Class.new do
      include Strapi::ControllerMethods
    end
  }
  subject(:controller_instance) { controller.new }

  describe '#index' do
    let(:record_factory) { double('Widget', to_s: 'Widget', all: relation) }
    let(:relation) { instance_double('relation') }
    let(:permitted_filter_params) { double('permitted_filter_params') }
    let(:filter_params) { double('filter_params', permit!: permitted_filter_params) }
    let(:filter_instance) { double('filter_instance', scope: relation) }

    before do
      # define methods required on controller instance
      allow(controller_instance).to receive(:params).and_return({
        filter: filter_params
      })
      allow(controller_instance).to receive(:record_factory).and_return(record_factory)
      allow(controller_instance).to receive(:allowed_sort_keys)
      allow(controller_instance).to receive(:policy_scope).and_return(relation)
      allow(controller_instance).to receive(:serializer_includes).and_return(['included'])
      allow(controller_instance).to receive(:respond_with)

      # define methods used on relation:
      # ActiveRecord::Relation chainable methods
      %i(order page per includes).each do |method|
        allow(relation).to receive(method).and_return(relation)
      end
      # ActiveRecord::Relation pagination methods
      %i(current_page next_page prev_page total_pages total_count).each do |method|
        allow(relation).to receive(method).and_return(method)
      end

      # define methods required on filter
      allow(WidgetFilter).to receive(:new).and_return(filter_instance)

      # actually call the index method
    end

    after do
      controller_instance.index
    end

    it "depends on a `record_factory` method in the controller to retrieve the model class" do
      expect(controller_instance).to receive(:record_factory)
    end

    it "retrieves all records from the record factory" do
      expect(record_factory).to receive(:all)
    end

    it "retrieves a query corresponding to the model" do
      # but doesn't use it--should it be responsible for passing it along to the filter?
      expect(WidgetQuery).to receive(:new).with(permitted_filter_params)
    end

    it "retrieves a filter corresponding to the model" do
      expect(WidgetFilter).to receive(:new).with({
        query: WidgetQuery,
        initial_scope: relation
      })
    end

    it "depends on an `allowed_sort_keys` method in the controller" do
      expect(controller_instance).to receive(:allowed_sort_keys)
    end

    # mock the sort class?

    it "uses the policy scope" do
      expect(controller_instance).to receive(:policy_scope).with(relation)
    end

    it "depends on a `serializer_includes` method in the controller" do
      expect(controller_instance).to receive(:serializer_includes)
    end

    it "responds with the relation and pagination metadata" do
      expect(controller_instance).to receive(:respond_with).with(relation,
        {
          include: ['included'],
          meta: {
            pagination: {
              current_page: :current_page,
              next_page: :next_page,
              prev_page: :prev_page,
              total_pages: :total_pages,
              total_count: :total_count,
            }
          }
        }
      )
    end

    context "no filter is provided" do
      before do
        allow(controller_instance).to receive(:params).and_return({
          filter: nil
        })
      end

      it "filters with an empty query object" do
        expect(WidgetQuery).to receive(:new).with({})
      end
    end
  end
end
