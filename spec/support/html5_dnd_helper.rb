# frozen_string_literal: true

# Helper for simulating HTML5 drag-and-drop in feature specs.
# Capybara's drag_to uses Selenium ActionBuilder (mouse events),
# which doesn't trigger react-dnd's HTML5Backend listeners.
# This dispatches real DragEvent objects with a DataTransfer so
# react-dnd recognizes the interaction.
module Html5DndHelper
  # Simulate dragging +source+ and dropping it onto +target+.
  # Both arguments should be Capybara node elements.
  def html5_drag_to(source, target)
    page.execute_script(<<~JS, source.native, target.native)
      (function(src, tgt) {
        // react-dnd HTML5Backend sets draggable="true" on connected
        // drag sources and attaches its dragstart listener there.
        // If the Capybara node is a wrapper (e.g. <li>), drill into
        // the actual draggable element so the event hits the right
        // listener.
        var draggableSrc = src.getAttribute('draggable') === 'true'
          ? src : src.querySelector('[draggable="true"]') || src;
        var draggableTgt = tgt.getAttribute('draggable') === 'true'
          ? tgt : tgt.querySelector('[draggable="true"]') || tgt;

        var dt = new DataTransfer();

        var srcRect = draggableSrc.getBoundingClientRect();
        var tgtRect = draggableTgt.getBoundingClientRect();

        var srcX = Math.round(srcRect.left + srcRect.width / 2);
        var srcY = Math.round(srcRect.top + srcRect.height / 2);
        var tgtX = Math.round(tgtRect.left + tgtRect.width / 2);
        var tgtY = Math.round(tgtRect.top + tgtRect.height / 2);

        function fire(el, type, x, y) {
          el.dispatchEvent(new DragEvent(type, {
            dataTransfer: dt,
            bubbles: true,
            cancelable: true,
            clientX: x,
            clientY: y,
            screenX: x,
            screenY: y
          }));
        }

        fire(draggableSrc, 'dragstart', srcX, srcY);
        fire(draggableTgt, 'dragenter', tgtX, tgtY);
        fire(draggableTgt, 'dragover',  tgtX, tgtY);
        fire(draggableTgt, 'drop',      tgtX, tgtY);
        fire(draggableSrc, 'dragend',   tgtX, tgtY);
      })(arguments[0], arguments[1]);
    JS
  end
end

RSpec.configure do |config|
  config.include Html5DndHelper, type: :feature
end
