import Scroll from 'react-scroll';

export class ArticleScroll {
  constructor() {
    this.scroller = Scroll.scroller;
    this.animateScroll = Scroll.animateScroll;
    this.scrollObject = {};
    this.currentPosition = -Infinity;
    this.currentCoordinate = null;
    this.currentName = null;
    this.scrollTop = true;
    this.nextPosition = null;
    this.bump = false;
  }
  // Stores highlighted paragraphs and position with users name as key
  createScrollObject(titles, users) {
    const paragraphs = Array.from(titles);
    // Adds paragraph containing highlighting along with position and index values to scrollObject
    paragraphs.forEach((paragraph, index = 0) => {
      users.forEach((user) => {
        if (this.scrollObject[user.name] === undefined) {
          const userInfo = {
            filteredParagraphs: [],
            index: 0,
          };
          this.scrollObject[user.name] = userInfo;
        }
        if (paragraph.querySelector(`span.token-editor-${user.userid}`) !== null) {
          const resObj = {
            paragraph,
            position: index,
            coordinates: paragraph.getBoundingClientRect()
          };
          this.scrollObject[user.name].filteredParagraphs.push(resObj);
        }
      });
    });
  }

  // Scrolling Logic, Scrolls to paragraph that contains revision by user
  scrollTo(name, scrollBox) {
    this.bump = false;
    const paragraphs = this.scrollObject[name].filteredParagraphs;
    const length = paragraphs.length;
    this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;

    // Finds closest edit if user switchs to a different editor
    if (name !== this.currentName && this.currentName !== null) {
      this.findClosestEdit(name, paragraphs);
    }
    // Checks if nextPosition is in view, finds closest edit not in view
    if (this.scrollTop === true) {
      this.findInView(name, paragraphs, length, scrollBox);
    }

    // Check Minimum distance, this prevents the scroll from only scrolling short distances
    if (this.currentCoordinate !== null && this.bump === false && this.scrollTop !== true) {
      this.findDistance(name, paragraphs, length);
    }

    const index = this.scrollObject[name].index;
    const id = this.findId(paragraphs[index].paragraph);

    this.currentName = name;
    this.currentCoordinate = this.nextPosition;
    this.currentPosition = paragraphs[index].position;

    if (this.bump === true || length === 1) {
      this.scrollBump(id);
      this.scrollTop = true;
    } else {
      // Scrolling function, either scrolls edit to the top of the page or scrolls edit till in view at bottom of page
      this.scroller.scrollTo(id, {
        duration: 150,
        delay: 100,
        smooth: true,
        containerId: 'article-scrollbox-id',
        offset: this.scrollTop === true ? -50 : (scrollBox.clientHeight - paragraphs[index].coordinates.height - 50) * -1,
      });
    }
    if (index >= length - 1) {
      this.scrollObject[name].index = 0;
      this.scrollTop = true;
    } else {
      this.scrollObject[name].index += 1;
    }
  }

  findClosestEdit(name, paragraphs) {
    for (let i = 0; i < paragraphs.length; i += 1) {
      const paragraph = paragraphs[i];
      // Set nextPosition to closest greater position
      if (paragraph.position > this.currentPosition) {
        this.nextPosition = paragraphs[i].coordinates;
        this.scrollObject[name].index = i;
        break;
        // If all edits are above current edit then reset to first edit
      } else if (i === paragraphs.length - 1) {
        this.nextPosition = paragraphs[0].coordinates;
        this.scrollObject[name].index = 0;
        this.scrollTop = true;
      }
    }
  }

  findInView(name, paragraphs, length, scrollBox) {
    const savedIndex = this.scrollObject[name].index - 1;
    while (this.currentCoordinate !== null && this.isInView(scrollBox, this.currentCoordinate, this.nextPosition) === true) {
      this.scrollObject[name].index += 1;
      if (this.scrollObject[name].index >= length) {
        // If every edit is in view, bump scroll window
        if (savedIndex === 0) {
          this.scrollObject[name].index = savedIndex;
          this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
          this.bump = true;
          break;
          // If looping back to top set nextPosition to first edit
        } else if (savedIndex < 0) {
          this.scrollObject[name].index = 0;
          this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
          break;
          // Else scroll to last edit
        } else {
          this.scrollObject[name].index = length - 1;
          this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
          break;
        }
      }
      this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
      this.scrollTop = false;
    }
  }

  findDistance(name, paragraphs, length) {
    while (this.checkDistanceMin(this.currentCoordinate, this.nextPosition) === false) {
      this.scrollObject[name].index += 1;
      if (this.scrollObject[name].index >= length) {
        this.scrollObject[name].index = length - 1;
        this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
        break;
      }
      // If nextPosition is to far then set nextPostion to previous.
      if (this.checkDistanceMax(this.nextPosition, paragraphs[this.scrollObject[name].index].coordinates) === true) {
        this.scrollObject[name].index -= 1;
        this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
        break;
      }
      this.nextPosition = paragraphs[this.scrollObject[name].index].coordinates;
    }
  }

  // Check from top of current postion + scrollWindow height
  isInView(window, curr, next) {
    if (curr.top + window.clientHeight - 50 > next.bottom && curr.bottom < next.top) return true;

    return false;
  }

  // Finds id for scroll distination
  findId(element) {
    if (element.id) return element.id;

    const children = Array.from(element.children);

    for (let i = 0; i < children.length; i += 1) {
      const child = children[i];
      if (child.id) return child.id;
    }
  }

  // Quickly bumps the scroll window down to show the are now relevant edits below
  scrollBump(id) {
    this.animateScroll.scrollMore(25, {
      duration: 25,
      delay: 0,
      smooth: true,
      containerId: 'article-scrollbox-id',
    });

    this.scroller.scrollTo(id, {
      duration: 150,
      delay: 100,
      smooth: true,
      containerId: 'article-scrollbox-id',
      offset: -50,
    });
  }

  checkDistanceMin(curr, next) {
    return curr.bottom + 250 <= next.top;
  }

  checkDistanceMax(curr, next) {
    return next.top - curr.bottom > 1000;
  }
}

export default ArticleScroll;
