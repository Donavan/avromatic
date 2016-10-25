describe Avromatic do
  it "has a version number" do
    expect(Avromatic::VERSION).not_to be_nil
  end

  describe ".build_schema_registry" do
    context "when the registry_url is unset" do
      before { Avromatic.registry_url = nil }

      it "raises an error" do
        expect { Avromatic.build_schema_registry }
          .to raise_error('Avromatic must be configured with a registry_url')
      end
    end

    context "when the registry_url is set" do
      let(:registry_url) { 'http://registry.example.com' }

      before do
        Avromatic.registry_url = registry_url
      end

      it "returns a CachedSchemaRegistryClient" do
        allow(AvroTurf::SchemaRegistry).to receive(:new).and_call_original
        expect(Avromatic.build_schema_registry).to be_a(AvroTurf::CachedSchemaRegistry)
        expect(AvroTurf::SchemaRegistry).to have_received(:new)
          .with(Avromatic.registry_url, logger: Avromatic.logger)
      end

      it "does not cache the schema registry client" do
        expect(Avromatic.build_schema_registry).not_to equal(Avromatic.build_schema_registry)
      end
    end
  end

  context "eager loading models" do
    before do
      stub_const('NestedRecord', Avromatic::Model.model(schema_name: 'test.nested_record'))
      described_class.nested_models.clear
    end

    context "at the end of configure" do
      it "registers models" do
        described_class.configure do |config|
          config.eager_load_models = NestedRecord
        end
        expect(described_class.nested_models.registered?('test.nested_record')).to eql(true)
      end
    end

    describe "#prepare!" do
      before do
        stub_const('ValueModel', Avromatic::Model.model(schema_name: 'test.value'))
      end

      it "clears the registry" do
        described_class.prepare!
        expect(described_class.nested_models.registered?('test.value')).to eql(false)
      end

      it "registers models" do
        described_class.eager_load_models = %w(NestedRecord)
        described_class.prepare!
        expect(described_class.nested_models.registered?('test.value')).to eql(false)
      end
    end
  end
end
