# encoding: utf-8

require_relative 'spec_helper'

describe Myaso::Mystem do
  describe 'analysis of dictionary words' do
    subject { Myaso::Mystem.analyze('СТАЛИ') }

    it 'is ambiguous' do
      subject.length.must_equal 2
    end

    it 'is a dictionary word' do
      subject.each { |s| s.quality.must_equal :dictionary }
    end

    it 'lemmatizes' do
      subject.map(&:lemma).sort!.must_equal %w(сталь становиться)
    end

    it 'normalizes' do
      subject.each { |s| s.form.must_equal 'стали' }
    end

    it 'analyzes' do
      subject.map { |s| s.msd.pos.to_s }.sort!.must_equal %w(noun verb)
    end
  end

  describe 'analysis of bastard words' do
    subject { Myaso::Mystem.analyze('дОлБоЯщЕрА') }

    it 'is unambiguous' do
      subject.length.must_equal 1
    end

    it 'is really a dictionary word' do
      subject.first.quality.must_equal :bastard
    end

    it 'lemmatizes' do
      subject.first.lemma.must_equal 'долбоящер'
    end

    it 'normalizes' do
      subject.first.form.must_equal 'долбоящера'
    end

    it 'analyzes' do
      subject.first.msd.pos.must_equal :noun
    end
  end

  describe 'form enumeration' do
    let(:lemma) { Myaso::Mystem.analyze('человеком').first }

    subject { Myaso::Mystem.forms('человеком', 3890) }

    it 'enumerates forms' do
      subject.length.must_equal 14
    end

    it 'works for lemmas' do
      subject.must_equal lemma.forms
    end
  end

  describe 'inflection' do
    let(:lemma) { Myaso::Mystem.analyze('людьми').first }

    subject { lemma.inflect(:number => :plural, :case => :dative) }

    it 'is ambiguous' do
      subject.length.must_equal 2
    end

    it 'inflects' do
      subject.map!(&:form).sort!.must_equal %w(людям человекам)
    end
  end
end
