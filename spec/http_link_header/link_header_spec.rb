# frozen_string_literal: true

RSpec.describe HttpLinkHeader::LinkHeader do
  describe 'Class methods' do
    describe '.parse' do
      subject { described_class.parse(target) }

      parameterized do
        where :target, :expected_value, :section_count, size: 3 do
          [
            [
              %(</>; rel="next"),
              [HttpLinkHeader::Link.new('/', rel: 'next')],
              1
            ],
            [
              '</next>; rel="next"; title="next page", ' \
                '</prev>; rel="previous"; title="previous page"',
              [
                HttpLinkHeader::Link.new('/next', rel: 'next', title: 'next page'),
                HttpLinkHeader::Link.new('/prev', rel: 'previous', title: 'previous page')
              ],
              2
            ],
            [
              '<http://localhost/next>; rel="next"; title="next page"; hreflang="ja"; media="(min-width: 801px)"; type="text/plain", ' \
                '<http://localhost/prev>; rel="previous"; title="previous page"; hreflang="ja"; media="(min-width: 801px); type="text/plain"',
              [
                HttpLinkHeader::Link.new('http://localhost/next', rel: 'next', title: 'next page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain'),
                HttpLinkHeader::Link.new('http://localhost/prev', rel: 'previous', title: 'previous page', hreflang: 'ja', media: '(min-width: 801px)', type: 'text/plain')
              ],
              2
            ]
          ]
        end

        with_them do
          it do
            link_header = subject
            expect(link_header.links.size).to eq(expected_value.size)
            section_count.times do |i|
              expect(link_header.links[i].url).to eq(expected_value[i].url)
              expect(link_header.links[i].attributes).to eq(expected_value[i].attributes)
            end
          end
        end
      end
    end

    describe '.generate' do
      subject { described_class.generate(*links) }

      parameterized do
        where :links, :expected_value, size: 2 do
          [
            [
              HttpLinkHeader::Link.new('/?page=1', rel: 'previous'),
              '</?page=1>; rel="previous"'
            ],
            [
              [
                HttpLinkHeader::Link.new('/?page=1', rel: 'previous'),
                HttpLinkHeader::Link.new('/?page=3', rel: 'next'),
              ],
              '</?page=1>; rel="previous", </?page=3>; rel="next"'
            ]
          ]
        end

        with_them do
          it { is_expected.to eq(expected_value) }
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#generate' do
      context '引数に渡す時に展開しない時' do
        subject { instance.generate }

        let(:instance) { described_class.new(*args) }

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
                ''
              ]
            ]
          end

          with_them do
            it { is_expected.to eq(expected_value) }
          end
        end
      end

      context '引数をArray<LinkHeader>で展開した場合' do
        subject { instance.generate }

        let(:instance) { described_class.new(*args) }

        parameterized do
          where :args, :expected_value, size: 2 do
            [
              [
                [nil],
                ''
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

    describe '#add_link' do
      let(:instance) { described_class.new }

      subject { instance.add_link(url, options) }

      let(:url) { '/?page=2' }
      let(:options) { { rel: 'next' } }

      it 'add Link instance to links' do
        expect { subject }.to change { instance.present? }.from(false).to(true)
        expect(instance.links.first).to be_a(HttpLinkHeader::Link)
      end
    end

    describe '#present?' do
      let(:instance) { described_class.new }

      subject { instance.present? }

      context 'When added link' do
        before do
          instance.add_link('/', rel: 'test')
        end

        it { is_expected.to eq(true) }
      end

      context 'When not added link' do
        it { is_expected.to eq(false) }
      end
    end

    describe '#find_by' do
      let(:link_header) do
        described_class.new(
          expected_link,
          HttpLinkHeader::Link.new('/dummy', rel: 'dummy')
        )
      end

      subject { link_header.find_by(attribute, value) }

      parameterized do
        where :attribute, :value, :expected_link, size: 5 do
          [
            [:rel, 'next', HttpLinkHeader::Link.new('/', rel: 'next')],
            [:hreflang, 'ja', HttpLinkHeader::Link.new('/', hreflang: 'ja')],
            [:title, 'TITLE', HttpLinkHeader::Link.new('/', title: 'TITLE')],
            [:media, '(min-width: 801px)', HttpLinkHeader::Link.new('/', media: '(min-width: 801px)')],
            [:type, 'text/plain', HttpLinkHeader::Link.new('/', type: 'text/plain')],
          ]
        end

        with_them do
          it { is_expected.to eq(expected_link) }
        end
      end
    end
  end
end
