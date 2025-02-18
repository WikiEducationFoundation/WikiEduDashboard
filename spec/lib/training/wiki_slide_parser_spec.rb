# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/wiki_slide_parser"

describe WikiSlideParser do
  let(:source_wikitext) do
    <<~WIKISLIDE
      <noinclude><languages /></noinclude>
      == <translate> <!--T:1--> E3: Situations you might encounter </translate> ==


      <translate><!--T:2--> Even though all efforts should be made to ensure that events are safe spaces for contributors to meet, congregate, and collaborate, there may be instances where you may observe situations that may make you or others feel uncomfortable, in a minor or major way. All of these violations can and should be addressed whether they occur against you or whether you observe them occurring against another person. This list is not meant to be exclusive – rare or unusual cases can always come up.</translate>

      * '''<translate><!--T:3--> Minor to moderate safe spaces violations</translate>'''<translate> <!--T:4--> usually consist of inappropriate comments, on-wiki arguments becoming a hostile or heated in-person debate, or inappropriate content that may be displayed in a presentation. These violations, especially, may not always be intentionally designed to upset others, but should nevertheless be addressed if they occur.</translate>
      * '''<translate><!--T:5--> Major safe spaces violations</translate>'''<translate> <!--T:6--> are situations where someone experiences a great deal of stress or feels threatened because of abusive conduct such as targeted harassment, explicit verbal personal attacks, implicit physical or sexual threats, or repeated unwanted actions after an explicit request to stop.</translate>
      * '''<translate><!--T:7--> Locally or globally banned users</translate>'''<translate> <!--T:8--> are not permitted to attend events. If you become aware of one being present at an event, keep in mind that the presence alone of a locally or globally banned user is considered to be a friendly space violation and should be reported to the EOT. Even if you don't feel immediately threatened by the individual, it's very possible that there are concerns outside of your knowledge and/or other attendees who could feel significant concern.</translate>
      * '''<translate><!--T:9--> Critical safety violations</translate>'''<translate> <!--T:10--> such as physical or sexual assault and abuse are extremely rare; however, when such incidents are observed or reported, they must be taken extremely seriously. </translate>
      * '''<translate><!--T:11--> Medical emergencies</translate>'''<translate> <!--T:12--> may also be encountered. Even though a medical emergency may not necessarily be the result of altercations with another person while at the event, it also needs to be treated as a matter of priority by the EOT.</translate>

      <translate><!--T:13--> Bear in mind that you, as the event organizer or as a volunteer, are also entitled to feel safe at an event. Incidents involving you should be treated just as seriously. Having a backup investigator to help in such a case is important. We'll talk more about this later in the training.</translate>

      {{Training module button
      | link = https://example.com
      | text = Example link
      }}

    WIKISLIDE
  end

  let(:translated_wikitext) do
    <<~WIKISLIDE
      <noinclude><languages /></noinclude>
      ==  E3: Situaciones que podrías enfrentar  ==
      Aunque se hagan los mayores esfuerzos para asegurarse que los eventos sean espacios seguros en donde se reúnen y colaboran los contribuyentes, puede llegar a haber situaciones en las cuales tu o alguien mas se pueda sentir incomodo ya sea de forma ligera o grave. Todas estas transgresiones pueden, y deben de ser tratadas si son dirigidas hacia ti o alguien mas. Esta lista no es exhaustiva, se pueden llegar a dar casos extraordinarios.

      * '''Transgresiones sutiles o moderadas a los espacios seguros''' por lo general consisten de comentarios no apropiados, argumentos en-wiki tornados hostil en persona o contenido inapropiado en una presentación. Estas situaciones en especial, no siempre tienen la intención de molestar o ofender a otros, sin embargo deben de ser tratadas.
      * '''Transgresiones graves a espacios seguros''' son situaciones en donde alguien esta en una situación de mucho estrés o se siente amenazado por conducta abusiva tal como acoso dirigido hacia el agredido, ataques verbales explícitos hacia la persona, amenazas físicas o sexuales implícitas o acciones no deseadas repetidas después de pedir explícitamente desistir a estas.
      * '''No es permitido que usuarios locales o globales suspendidos''' asistan a eventos. En caso de tener conocimiento de un usuario suspendido asistiendo un evento, este debera ser reportado al EOT, ya que esta situación es una transgresion al espacio seguro. Aun que no hayas sido agredido por el individuo, es posible que otras personas tengan problemas de los que no estes percatado.
      * '''Transgresiones criticas de seguridad''' tal como físicas, acoso sexual y abuso son muy poco comunes, sin embargo al ser percatadas o reportadas, estas deben ser tomadas con extrema seriedad.
      * '''Emergencias medicas''' también se pueden llegar a suscitar. Aunque no sean causadas por altercados entre personas en un evento, estas deben ser tratadas como una prioridad por el EOT.

      Toma en mente que tu, en rol de organizador o voluntario, tienes el derecho a sentirte seguro en un evento. Incidentes que te involucren deben ser tratados con la misma seriedad. En estos casos es importante tener un investigador de apoyo. Trataremos este tema mas a fondo en la capacitación.
    WIKISLIDE
  end

  let(:quiz_wikitext) do
    <<~WIKISLIDE
      == Five Pillars quiz ==

      {{Training module quiz

      | question = An editor has written to you saying that another editor has revealed personal information about them on-wiki in an attempt to intimidate them from working on an article about a contentious subject. They have supplied a link to a diff. Before investigating further, you want to acknowledge the report. Should you write:
      | correct_answer_id = 1
      | answer_1 = Present the facts in a careful way, to persuade readers to draw certain conclusions.
      | explanation_1 = Incorrect. Remember, a Wikipedia article should be neutral, balanced, and fair to all views. You want readers to have access to facts, and trust that those facts will lead them to their own conclusions. This is the policy known as Neutral Point of View.
      | answer_2 = Replicate the best information from published authors, word-for-word.
      | explanation_2 = Incorrect. You should be using reliable, published information, but you want to be very careful not to plagiarize, or closely paraphrase, those authors. Instead, you should seek out good information and summarize those facts using your own words.

      }}
    WIKISLIDE
  end

  let(:image_wikitext) do
    <<~WIKISLIDE
      == Five Pillars: The core rules of Wikipedia ==

      {{Training module image
      | image = File:Palace_of_Fine_Arts%2C_five_pillars.jpg
      | source = https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Palace_of_Fine_Arts%2C_five_pillars.jpg/640px-Palace_of_Fine_Arts%2C_five_pillars.jpg
      | layout = alt-layout-40-right
      | credit = Photo by Eryk Salvaggio
      }}

      Wikipedia is the encyclopedia anyone can edit, but there's a lot of collaboration behind every article. You'll work with many people to build Wikipedia.
    WIKISLIDE
  end

  let(:multi_image_wikitext) do
    <<~WIKISLIDE
      == Five Pillars: The core rules of Wikipedia ==

      {{Training module image
      | image = File:Palace_of_Fine_Arts%2C_five_pillars.jpg
      | source = https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Palace_of_Fine_Arts%2C_five_pillars.jpg/640px-Palace_of_Fine_Arts%2C_five_pillars.jpg
      | layout = alt-layout-40-right
      | credit = Photo by Eryk Salvaggio
      }}

      {{Training module image
      | image = File:Find_a_program.png
      | source = https://upload.wikimedia.org/wikipedia/commons/4/48/Find_a_program.png
      | layout = alt-layout-40-right
      | credit = In the top right of the interface, next to the Log-out and User-name buttons, you can find the language switcher
      }}

      Wikipedia is the encyclopedia anyone can edit, but there's a lot of collaboration behind every article. You'll work with many people to build Wikipedia.
    WIKISLIDE
  end

  let(:video_wikitext) do
    <<~WIKISLIDE
      == Starting new programs ==

      If you are the host of a program or event, you need to be able to create events. There are two different ways to create a program: through creating a new one, or cloning an existing event.

      {{Training module image
      | image = File:Palace_of_Fine_Arts%2C_five_pillars.jpg
      | source = https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Palace_of_Fine_Arts%2C_five_pillars.jpg/640px-Palace_of_Fine_Arts%2C_five_pillars.jpg
      | layout = alt-layout-40-right
      | credit = Photo by Eryk Salvaggio
      }}

      {{Training module video
      | video = File:How to Use the Dashboard (2 of 5).webm
      | source = https://upload.wikimedia.org/wikipedia/commons/7/79/How_to_Use_the_Dashboard_%282_of_5%29.webm
      | caption = How to Use the Dashboard (2 of 5)
      }}

    WIKISLIDE
  end

  let(:translate_markup_variant) do
    <<~WIKISLIDE
      <noinclude><languages/></noinclude>
      <translate>== Five Pillars: The core rules of Wikipedia == <!--T:1-->

      <!--T:2-->
      {{Training module image
      | image = File:Palace_of_Fine_Arts%2C_five_pillars.jpg
      | source = https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Palace_of_Fine_Arts%2C_five_pillars.jpg/640px-Palace_of_Fine_Arts%2C_five_pillars.jpg
      | layout = alt-layout-40-right
      | credit = Photo by Eryk Salvaggio
      }}

      <!--T:3-->
      Wikipedia is the encyclopedia anyone can edit, but there's a lot of collaboration behind every article. You'll work with many people to build Wikipedia. To collaborate effectively, you'll want to follow the five key principles, or pillars, of Wikipedia.

      <!--T:4-->
      Wikipedia's Five Pillars are:

      <!--T:5-->
      * Wikipedia is an online encyclopedia
      * Wikipedia has a neutral point of view
      * Wikipedia is free content
      * Wikipedians should interact in a respectful and civil manner
      * Wikipedia does not have firm rules

      <!--T:6-->
      Let’s explore these a bit.</translate>
    WIKISLIDE
  end

  # https://meta.wikimedia.org/w/index.php?title=Training_modules/dashboard/slides/12102-introduction/eu&action=edit
  let(:translated_wikitext_with_leading_whitespace) do
    <<~WIKISLIDE

      == Edizio ekintzei buruzko sarrera ==

      {{Training module video|
      video =  File:Esto es un editatón de Wikipedia.webm
      |source = https://www.youtube-nocookie.com/embed/94KtOE39Hyw
      |caption = Mexiko DFko Museo Soumayan egindako 72 orduko editatoia irudikatzen duen bideoa}}

      Wikipediako edizio ekintzak, askotan izendapen bera erabiliagatik, askotarikoak izan daitezke, eta helburu desberdinak dituzte, adibidez:
      * ''Editatoiak'': gai jakin baten inguruko ekintza, Wikipedian dauden zuloei buruz kontzientzia areagotzeko eta gai horretan lankide gehiago izatera bultzatzeko.
      * ''Barrualderako baimenak'': ikerketa edo kultura erakunde bateko bildumak, prozesuak edo ezagutza espezializatuari erreparatu edo horiek erakusten dituzten ekintzak.
      * ''Edizio lantegiak/trebakuntza tailerrak'': parte-hartzaileak edizioan trebatzea da garrantzitsuagoa edukia sortzea baino.
      * ''Edizio topaketak'': eskarmentua duten editoreak edukiak sortzera bultzatzeko ekintzak, maiztasunez ordu edo toki jakin batean antolatutakoak askotan.
      * ''Mikroekarpenen ekintzak'': bertaratze bidezko ekintza hauetan, ahalegina egiten da  arazo jakin bat konpontzeko edo ekarpen txiki errepikatuak egiteko.

      Trebakuntza honek arlo jakin bati eta eduki sorrerari buruzko ekintzei erreparatzen die batez ere, maiz 'editatoi' deitutakoei, nahiz eta beste edizio ekintzetarako egokiak diren gomendioak eta jarraibideak ematen diren. Editatoiek forma eta tamaina desberdinak izaten dituzte, hasi parte-hartzaile gutxi batzuetako ordubeteko ekintza txikietatik eta dozenaka lankide biltzen dituzten 72 orduko ekintzetara. Ekintza horiek askotariko gaiak biltzen dituzte, adibidez (baina ez bakarrik):
      * [[w:eu:Wikipedia:Genero_oreka|Generoko zuloa]] berdindu, emakume zientzialari eta artistak landuz.
      * Interneteko joera sistemikoa berdintzeko jatorrizko herrien edo hizkuntza gutxituen agerpen txikia garatuz.
      * Adituengandik edo erakundeengandik ezagutza sakona partekatu.
      * Tokiko historia edo ondare lekuei buruzko zuloa berdindu.

      Editatoi bat eta beste edizio ekintzak muntatzeko, zenbait elementu behar dira: denbora, elkartzeko espazio bat, Wikimediako proiektuei buruzko ulermena eskain dezaketen ekintzen gidariak, eta Wikimedia proiektuetan ekarpenak nola egin ikasi nahi duen jendea. Horrelako bilkurak antolatzea erronka izan daiteke, hainbat detaile kontuan hartzea eska dezakeena.
      <noinclude>
      [[Category:Editathon training slides]]
      </noinclude>
    WIKISLIDE
  end

  # https://meta.wikimedia.org/wiki/Training_modules/editathons/library
  let(:editathons_library_wikitext) do
    <<~WIKITEXT
      <noinclude><languages /></noinclude>
      <translate>== Running Editathons and other Editing Events == <!--T:1--></translate>

      <translate><!--T:2--> This set of modules focuses on the development of editathons and other editing events.</translate>

      {{Training module category
      | title = <translate><!--T:3--> Running Editathons</translate>
      | description = <translate><!--T:4--> Training modules for running an editathon or other similar editing events. The training takes about 1.5-2 hours, and is in three parts.</translate>
      | module_name_1 = <translate><!--T:5--> Module 1: Defining your event</translate>
      | module_slug_1 = defining-your-event
      | module_description_1 = <translate><!--T:6--> What decisions do you need to make to identify and create and editing event?</translate>
      | module_name_2 =<translate> <!--T:7--> Module 2: Planning well before the Editathon</translate>
      | module_slug_2 = planning-well-before-the-event
      | module_description_2 = <translate><!--T:8--> Logistics, decisions and outreach that can be done well before editing events — including Venue logistics, Communications plans and preparing contribution topics.</translate>
      | module_name_3 = <translate><!--T:9--> Module 3: Planning leading up to the event</translate>
      | module_slug_3 = planning-leading-up-to-the-event
      | module_description_3 = <translate><!--T:10--> Logistics, preparation and concerns that might arise in the final weeks before the event and during the event.</translate>
      }}
    WIKITEXT
  end

  # https://meta.wikimedia.org/w/index.php?title=Special:ExportTranslations&language=es&group=page-Training+modules%2Fdashboard%2Flibraries%2Fediting-wikipedia
  let(:uncomplete_spanish_translation) do
    <<~WIKITEXT
      <noinclude><languages /></noinclude>
      <span lang="en" dir="ltr" class="mw-content-ltr">== Wikipedia Training Modules ==</span>#{' '}

      <span lang="en" dir="ltr" class="mw-content-ltr">This set of modules helps new editors get started with Wikipedia. This page lists every module, including specialized modules for particular topics.</span>

      {{Training module category
      | title =  <span lang="en" dir="ltr" class="mw-content-ltr">Basics</span>
      | description =  <span lang="en" dir="ltr" class="mw-content-ltr">These modules cover the basic rules of Wikipedia.</span>
      | module_name_1 =  <span lang="en" dir="ltr" class="mw-content-ltr">Wikipedia Essentials</span>
      | module_slug_1 = wikipedia-essentials
      | module_description_1 =  <span lang="en" dir="ltr" class="mw-content-ltr">An overview of Wikipedia's main rules</span>
      | module_name_2 = <span lang="en" dir="ltr" class="mw-content-ltr">Editing Basics</span>
      | module_slug_2 = editing-basics
      | module_description_2 =  <span lang="en" dir="ltr" class="mw-content-ltr">An introduction to editing Wikipedia pages</span>
      | module_name_3 =  <span lang="en" dir="ltr" class="mw-content-ltr">Evaluating Articles and Sources</span>
      | module_slug_3 = evaluating-articles
      | module_description_3 =  <span lang="en" dir="ltr" class="mw-content-ltr">Advice for thinking critically about Wikipedia article quality</span>
      }}
    WIKITEXT
  end

  let(:multiline_quiz_wikitext) do
    <<~WIKISLIDE
      {{Training module quiz
      | question = <translate>
      Take a look at this original (fictional) passage. Then, look at the options below. Choose the one you think is an acceptable way to present that information on Wikipedia.

      Passage:

      :"In 1967, only 25% of eligible Boston voters supported a measure to limit the space afforded to keeping cattle in the city. Dr. Bickford's research suggests that this was on account of the confusing language on the ballot measure, and that support for the measure would have been higher had the memorandum been more clearly stated on the ballot."

      '''How would you share this information in a Wikipedia article? '''</translate>
      | correct_answer_id = 3
      | answer_1 = <translate>Some answer text</translate>
      | explanation_1 = <translate>Some explanation</translate>
      }}
    WIKISLIDE
  end

  describe '#title' do
    it 'extracts title from translation-enabled source wikitext' do
      output = described_class.new(source_wikitext.dup).title
      expect(output).to eq('E3: Situations you might encounter')
    end

    it 'extracts title from translated source wikitext' do
      output = described_class.new(translated_wikitext.dup).title
      expect(output).to eq('E3: Situaciones que podrías enfrentar')
    end

    it 'handles nil input' do
      output = described_class.new(+'').title
      expect(output).to eq('')
    end

    it 'extracts only the title from variant translation markup formats' do
      output = described_class.new(translate_markup_variant.dup).title
      expect(output).to eq('Five Pillars: The core rules of Wikipedia')
    end

    it 'extracts the title from translated wikitext with leading whitespace' do
      output = described_class.new(translated_wikitext_with_leading_whitespace.dup).title
      expect(output).to eq('Edizio ekintzei buruzko sarrera')
    end

    it 'works for training libraries' do
      output = described_class.new(editathons_library_wikitext.dup).title
      expect(output).to eq('Running Editathons and other Editing Events')
    end

    it 'extracts title propery if span tags' do
      output = described_class.new(uncomplete_spanish_translation.dup).title
      expect(output).to eq('Wikipedia Training Modules')
    end
  end

  describe '#content' do
    it 'converts wiki markup to markdown' do
      output = described_class.new(source_wikitext.dup).content
      expect(output).to match(/\*\*Minor to moderate safe spaces violations\*\*/)
      output = described_class.new(translated_wikitext.dup).content
      expect(output).to match(/\*\*Transgresiones sutiles o moderadas a los espacios seguros\*\*/)
    end

    it 'converts an image template into figure markup' do
      output = described_class.new(image_wikitext.dup).content
      expect(output).to match(/Eryk Salvaggio/)
    end

    it 'converts multiple image templates into distinct figure markups' do
      output = described_class.new(multi_image_wikitext.dup).content
      expect(output).to include('five_pillars.jpg')
      expect(output).to include('Find_a_program.png')
    end

    it 'converts a video template into iframe markup' do
      output = described_class.new(video_wikitext.dup).content
      expect(output).to include('iframe>')
    end

    it 'includes a forced newline after figure markup' do
      # Markdown conversion outputs just one newline after figure markup, which
      # can result in the next line getting misparsed. Two newlines ensures that
      # the following content gets parsed as a new paragraph.
      output = described_class.new(image_wikitext.dup).content
      expect(output).to include("figure>\n\n")
    end

    it 'removes leading newlines' do
      output = described_class.new(source_wikitext.dup).content
      expect(output[0..10]).to eq('Even though')
    end

    it 'handles nil input' do
      output = described_class.new(''.dup).content
      expect(output).to eq('')
    end

    it 'strips span tags from content' do
      output = described_class.new(uncomplete_spanish_translation.dup).content
      expect(output).not_to match('<span')
    end
  end

  describe '#quiz' do
    it 'converts a wiki template into a hash representing a quiz' do
      output = described_class.new(quiz_wikitext.dup).quiz
      expect(output[:correct_answer_id]).to eq(1)
      expect(output[:answers].count).to eq(2)
    end

    it 'correctly parses multi-line quiz question with formatting' do
      quiz = described_class.new(multiline_quiz_wikitext.dup).quiz

      expect(quiz).to be_present
      expect(quiz[:question]).to include('Take a look at this original (fictional) passage')
      expect(quiz[:question]).to include('Passage:')
      expect(quiz[:question]).to include(
        'How would you share this information in a Wikipedia article?'
      )
      expect(quiz[:question]).not_to include(':"')
      expect(quiz[:question]).not_to include("'''")
    end
  end

  describe '#categories' do
    it 'extracts an array of category hashes from a wiki template' do
      output = described_class.new(editathons_library_wikitext.dup).categories
      expect(output.count).to eq(1)
      expect(output.first['modules'].count).to eq(3)
      expect(output.first['modules'].first['slug']).to eq('defining-your-event')
      expect(output.first['modules'].second['name'])
        .to eq('Module 2: Planning well before the Editathon')
      expect(output.first['modules'].third['description'])
        .to include('Logistics, preparation and concerns that might arise')
    end
  end
end
