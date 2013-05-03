# encoding: utf-8

# A Tagger model that can work with TnT data files.
#
class Myaso::Tagger::TnT < Myaso::Tagger::Model
  # A start tag for a sentence.
  #
  START = 'SENT'

  # A stop tag for a sentence.
  #
  STOP = 'SENT'

  # Unknown tag for token.
  #
  MISSING = '-'

  # Tokens consisting of a sequence of decimal digits.
  #
  CARD = '@CARD'

  # Decimal digits followed by punctuation.
  #
  CARDPUNCT = '@CARDPUNCT'

  # Decimal digits followed by any suffix.
  #
  CARDSUFFIX = '@CARDSUFFIX'

  # Decimal digits separated by dots, dashes, etc.
  #
  CARDSEPS = '@CARDSEPS'

  # Tag frequencies to handle unknown words.
  #
  UNKNOWN = '@UNKNOWN'

  attr_reader :ngrams_path, :lexicon_path

  # The tagging model is initialized by two data files. The first one is a
  # n-grams file that stores statistics for unigrams, bigrams, trigrams.
  # The second one is a lexicon file that stores words and their
  # frequencies in the source corpus.
  #
  # Please note that the learning stage is not so optimized, so the
  # initialization procedure may take about 120 seconds.
  #
  def initialize(ngrams_path, lexicon_path)
    @ngrams_path = File.expand_path(ngrams_path)
    @lexicon_path = File.expand_path(lexicon_path)
    super()
  end

  # If word is rare, it can be one of the following categories:
  # includes numbers, numbers and punctuation symbols, non-numbers
  # following numbers and unknown. Otherwise, word has it's own category.
  #
  def classify(word)
    return word unless rare? word
    case word
    when /^\d+$/ then CARD
    when /^\d+[.,;:]+$/ then CARDPUNCT
    when /^\d+\D+$/ then CARDSUFFIX
    when /^\d+[.,;:\-]+(\d+[.,;:\-]+)*\d+$/ then CARDSEPS
    else UNKNOWN
    end
  end

  # Tagger requires the sentence start symbol to be defined.
  #
  def start_symbol
    START
  end

  # Tagger requires the sentence stop symbol to be defined.
  #
  def stop_symbol
    STOP
  end

  # Parse n-grams and lexicon files, and compute statistics over them.
  #
  def learn!
    parse_ngrams!
    parse_lexicon!
    compute_interpolations!
  end

  # Parse the n-grams file.
  #
  def parse_ngrams!
    unigram, bigram = nil, nil

    read(ngrams_path) do |values|
      if !values[0] && !values[1]
        values[0], values[1] = unigram, bigram
      elsif !values[0] && values[1]
        values[0] = unigram
      end

      if values[0] && values[1] && values[2] && values[3] # a trigram
        ngrams[*values[0..2]] = values[3].to_i
      elsif values[0] && values[1] && values[2] && !values[3] # a bigram
        ngrams[*values[0..1]] = values[2].to_i
      elsif values[0] && values[1] && !values[2] && !values[3] # an unigram
        ngrams[values[0]] = values[1].to_i
      else
        raise 'dafuq i just read: %s' % values.inspect
      end

      unigram, bigram = values[0], values[1]
    end
  end

  # Parse the lexicon file.
  #
  def parse_lexicon!
    read(lexicon_path) do |values|
      values.compact!

      word, word_count, rare = values.shift, values.shift.to_i, false
      word = classify(word) if rare = (word_count == 1)

      lexicon[word] += word_count

      values.each_slice(2) do |tag, count|
        lexicon[word, tag] += count.to_i
      end
    end
  end

  # @private
  #
  def inspect
    sprintf('#<%s ngrams_path=%s lexicon_path=%s>', self.class.name,
      ngrams_path, lexicon_path)
  end

  private
  # Read the TnT data file.
  #
  def read(path)
    File.open(path) do |f|
      until f.eof?
        line = f.gets.chomp
        next if line.empty? || line =~ /^%%/
        yield line.split(/\t/).map! { |s| s.empty? ? nil : s }
      end
    end
  end
end