# frozen_string_literal: true

RSpec.describe HttpLinkHeader::LinkHeader do
  describe 'Class methods' do
    describe '.parse' do
      subject { described_class.parse(target) }

      parameterized do
        where :target, :expected_value, size: 3 do
          [
            [
              %(</>; rel="next"),
              [HttpLinkHeader::Link.new('/', rel: 'next')]
            ],
            [
              '</next>; rel="next"; title="next page", ' \
                '</prev>; rel="previous"; title="previous page"',
              [
                HttpLinkHeader::Link.new('/next', rel: 'next', title: 'next page'),
                HttpLinkHeader::Link.new('/prev', rel: 'previous', title: 'previous page')
              ]
            ],
            [
              '<http://localhost/next>; rel="next"; title="next page"; hreflang="ja"; media="(min-width: 801px)"; type="text/plain", ' \
                '<http://localhost/prev>; rel="previous"; title="previous page"; hreflang="ja"; media="(min-width: 801px); type="text/plain"',
              [
                HttpLinkHeader::Link.new('http://localhost/next', rel: 'next', title: 'next page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain'),
                HttpLinkHeader::Link.new('http://localhost/prev', rel: 'previous', title: 'previous page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain')
              ]
            ]
          ]
        end

        with_them do
          it do
            result = subject
            expect(result.size).to eq(expected_value.size)
            result.each_with_index do |r, i|
              expect(r.uri).to eq(expected_value[i].uri)
              expect(r.attributes).to eq(expected_value[i].attributes)
            end
          end
        end
      end
    end

    describe '.generate' do
      context '引数に渡す時に展開しない時' do
        subject { described_class.generate(*args) }

        parameterized do
          where :args, :expected_value, size: 5 do
            [
              [
                HttpLinkHeader::Link.new('/', rel: 'next'),
                '</>; rel="next"'
              ],
              [
                [
                  nil,
                  HttpLinkHeader::Link.new('/', rel: 'next')
                ],
                '</>; rel="next"'
              ],
              [
                [
                  HttpLinkHeader::Link.new('/next', rel: 'next'),
                  HttpLinkHeader::Link.new('/prev', rel: 'previous')
                ],
                '</next>; rel="next", ' \
                  '</prev>; rel="previous"'
              ],
              [
                [
                  HttpLinkHeader::Link.new('http://localhost/next', rel: 'next', title: 'next page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain'),
                  HttpLinkHeader::Link.new('http://localhost/prev', rel: 'previous', title: 'previous page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain')
                ],
                '<http://localhost/next>; rel="next"; title="next page"; hreflang="ja"; media="(min-width: 801px)"; type="text/plain", ' \
                  '<http://localhost/prev>; rel="previous"; title="previous page"; hreflang="ja"; media="(min-width: 801px)"; type="text/plain"'
              ],
              [
                nil,
                nil
              ]
            ]
          end

          with_them do
            it { is_expected.to eq(expected_value) }
          end
        end
      end

      context '引数をArray<LinkHeader>で展開した場合' do
        subject { described_class.generate(*args) }

        parameterized do
          where :args, :expected_value, size: 2 do
            [
              [
                [nil],
                nil
              ],
              [
                [
                  HttpLinkHeader::Link.new('/next', rel: 'next'),
                  HttpLinkHeader::Link.new('/prev', rel: 'previous')
                ],
                '</next>; rel="next", </prev>; rel="previous"'
              ]
            ]
          end

          with_them do
            it { is_expected.to eq(expected_value) }
          end
        end
      end
    end
  end
end
