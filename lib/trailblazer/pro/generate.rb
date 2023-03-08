require "representable/json"
require "trailblazer/activity/dsl/linear" # Railway.
require "ostruct"

module Trailblazer
  module Pro
    # Computes an {Intermediate} data structure from a TRB-editor.json file.
    module Generate
      Element = Struct.new(:id, :type, :data, :links)
      Link    = Struct.new(:target_id, :semantic)

      module Representer
        class Collaboration < Representable::Decorator  # Called {structure}.
          include Representable::JSON

          property :name
          collection :lanes, class: OpenStruct do
            property :name
            collection :elements, class: Element do
              property :id
              property :type
              property :data
              collection :links, class: Link do
                property :target_id
                property :semantic
              end
            end
          end
          collection :messages
        end
      end # Representer

      module_function

      def call(hash)
        _, (ctx, _) = Pipeline.invoke({hash: hash})

        ctx[:intermediate]
      end

      def transform_from_hash(ctx, hash:, parser: Representer::Collaboration, **)
        ctx[:structure] = parser.new(OpenStruct.new).from_json(hash)
      end

      def find_start_events(ctx, elements:, **)
        ctx[:start_events] = elements.find_all { |el| el.type == "Event" }
      end

      def compute_intermediate(ctx, elements:, start_events:, **)
        end_events   = elements.find_all { |el| el.type == "EndEventTerminate" } # DISCUSS: is it really called TERMINATE?

        inter = Activity::Schema::Intermediate

        wiring = elements.collect { |el|
          data = data_for(el)

          [inter.TaskRef(el.id, data), el.linksTo.collect { |arrow| inter.Out(semantic_for(**arrow.to_h), arrow.target) } ] }
        wiring = Hash[wiring]

        # end events need this stupid special handling
        # DISCUSS: currently, the END-SEMANTIC is read from the event's label.
        wiring = wiring.merge(Hash[
          end_events.collect do |_end|
            ref, = wiring.find { |ref, _| ref.id == _end.id }

            [ref, [inter.Out(semantic_for(**_end.to_h)|| raise, nil)]] # TODO: test the raise, happens when the semantic of an End can't be distinguished. # TODO: don't extract semantic from :label but from :data.
          end
        ])
        # pp wiring

        ctx[:intermediate] = inter.new(wiring, end_events.collect(&:id), start_events.collect(&:id))
      end

      # private

      def data_for(element)
        {type: element.type}.merge(element.data)
      end

      # We currently use the {:label} field of an arrow to encode an output semantic.
      # The {:symbol_style} part will be filtered out as semantic. Defaults to {:success}.
      def semantic_for(label:nil, **)
        return :success unless label

        extract_semantic(label)
      end

      def extract_semantic(label)
        label.to_sym
      end

      class Pipeline < Trailblazer::Activity::Railway
        step Generate.method(:transform_from_hash),   id: :transform_from_hash
        step Generate.method(:find_start_events),     id: :find_start_events
        step Generate.method(:compute_intermediate),  id: :compute_intermediate
      end
    end
  end
end
