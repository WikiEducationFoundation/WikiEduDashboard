# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/training/wiki_slide_parser"

describe WikiSlideParser do
  let(:source_wikitext) do
    <<-WIKISLIDE
<noinclude><languages /></noinclude>
== <translate> <!--T:1--> E3: Situations you might encounter </translate> ==
<translate><!--T:2--> Even though all efforts should be made to ensure that events are safe spaces for contributors to meet, congregate, and collaborate, there may be instances where you may observe situations that may make you or others feel uncomfortable, in a minor or major way. All of these violations can and should be addressed whether they occur against you or whether you observe them occurring against another person. This list is not meant to be exclusive – rare or unusual cases can always come up.</translate>

* '''<translate><!--T:3--> Minor to moderate safe spaces violations</translate>'''<translate> <!--T:4--> usually consist of inappropriate comments, on-wiki arguments becoming a hostile or heated in-person debate, or inappropriate content that may be displayed in a presentation. These violations, especially, may not always be intentionally designed to upset others, but should nevertheless be addressed if they occur.</translate>
* '''<translate><!--T:5--> Major safe spaces violations</translate>'''<translate> <!--T:6--> are situations where someone experiences a great deal of stress or feels threatened because of abusive conduct such as targeted harassment, explicit verbal personal attacks, implicit physical or sexual threats, or repeated unwanted actions after an explicit request to stop.</translate>
* '''<translate><!--T:7--> Locally or globally banned users</translate>'''<translate> <!--T:8--> are not permitted to attend events. If you become aware of one being present at an event, keep in mind that the presence alone of a locally or globally banned user is considered to be a friendly space violation and should be reported to the EOT. Even if you don't feel immediately threatened by the individual, it's very possible that there are concerns outside of your knowledge and/or other attendees who could feel significant concern.</translate>
* '''<translate><!--T:9--> Critical safety violations</translate>'''<translate> <!--T:10--> such as physical or sexual assault and abuse are extremely rare; however, when such incidents are observed or reported, they must be taken extremely seriously. </translate>
* '''<translate><!--T:11--> Medical emergencies</translate>'''<translate> <!--T:12--> may also be encountered. Even though a medical emergency may not necessarily be the result of altercations with another person while at the event, it also needs to be treated as a matter of priority by the EOT.</translate>

<translate><!--T:13--> Bear in mind that you, as the event organizer or as a volunteer, are also entitled to feel safe at an event. Incidents involving you should be treated just as seriously. Having a backup investigator to help in such a case is important. We'll talk more about this later in the training.</translate>
WIKISLIDE
  end

  let(:translated_wikitext) do
    <<-WIKISLIDE
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

  describe '#title' do
    it 'extracts title from translation-enabled source wikitext' do
      output = WikiSlideParser.new(source_wikitext.dup).title
      expect(output).to eq('E3: Situations you might encounter')
    end
    it 'extracts title from translation-enabled source wikitext' do
      output = WikiSlideParser.new(translated_wikitext.dup).title
      expect(output).to eq('E3: Situaciones que podrías enfrentar')
    end
  end

  describe '#content' do
    it 'converts wiki markup to markdown' do
      output = WikiSlideParser.new(source_wikitext.dup).content
      expect(output).to match(/\*\*Minor to moderate safe spaces violations\*\*/)
      output = WikiSlideParser.new(translated_wikitext.dup).content
      expect(output).to match(/\*\*Transgresiones sutiles o moderadas a los espacios seguros\*\*/)
    end
  end
end
