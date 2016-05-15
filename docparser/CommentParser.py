def ParseComment(text):
    parser = CommentParser(text)
    return parser.parse()

class Comment(object):
  def __init__(self):
    super(Comment, self).__init__()
    self.main = ''
    self.tags = []

class CommentParser(object):
  def __init__(self, text):
    self.text = text
    self.pos = 0
    self.doc = Comment()

  def peekChar(self):
    if self.pos >= len(self.text):
      return '\0'
    return self.text[self.pos]
  def getChar(self):
    if self.pos >= len(self.text):
      return '\0'
    self.pos += 1
    return self.text[self.pos - 1]
  def matchChar(self, c):
    if self.peekChar() != c:
      return False
    return self.getChar()

  def parse(self):
    while self.pos < len(self.text):
      if self.getChar() == '/':
        if self.matchChar('*'):
          self.parse_multiline()
        elif self.matchChar('/'):
          self.parse_singleline()
    return self.doc

  def parse_multiline(self):
    # Find the body of the comment.
    body_start = self.pos
    body_end = None
    while self.pos < len(self.text):
      if self.getChar() == '*':
        if self.getChar() == '/':
          body_end = self.pos - 2
          break
    if body_end is None:
      body_end = self.pos

    # Break the comment into lines.
    lines = self.text[body_start:body_end].splitlines()

    # Strip leading **<
    lines = [line.lstrip() for line in lines]
    lines = [line.lstrip('*') for line in lines]
    lines = [line.lstrip('<') for line in lines]

    # Strip whitespace and *.
    lines = [line.strip(' \v\t') for line in lines]
    lines = [line.replace('\t', ' ') for line in lines]
    self.parse_lines(lines)

  def parse_singleline(self):
    # Find the end of the single-line block.
    body_start = self.pos
    body_end = None
    first_char = True
    while self.pos < len(self.text):
      c = self.getChar()
      if c == '\r' or c == '\n':
        first_char = True
        continue
      if c.isspace() or not first_char:
        continue

      first_char = False
      if c == '/':
        if not self.matchChar('/'):
          body_end = self.pos - 1
          break
    if body_end is None:
      body_end = self.pos

    # Break the comment into lines.
    rawlines = self.text[body_start:body_end].splitlines()
    lines = []
    for line in rawlines:
      # Strip comment parts.
      line = line.lstrip()
      if line.startswith('//'):
        line = line.lstrip('/')

      # Strip whitespace.
      line = line.strip()
      line = line.replace('\t', ' ')
      lines.append(line)

    self.parse_lines(lines)

  def parse_lines(self, lines):
    block_tag = None
    block_lines = []
    for index, line in enumerate(lines):
      if line.startswith('@'):
        tag_end = line.find(' ', 1)
        if tag_end == -1 or tag_end == 1:
          continue

        if index != 0:
          self.push_block(block_tag, block_lines)

        block_tag = line[1:tag_end]
        block_lines = []
        line = line[tag_end+1:].strip()

        if block_tag == 'param':
          param_end = line.find(' ')
          if param_end != -1:
            block_tag += ':' + line[:param_end]
            line = line[param_end+1:].strip()
          else:
            block_tag += ':unknown'
      block_lines.append(line)
    self.push_block(block_tag, block_lines)

  def push_block(self, tag, lines):
    # Trim front and back empty lines.
    while len(lines) and not len(lines[len(lines) - 1]):
      lines.pop()
    while len(lines) and not len(lines[0]):
      lines = lines[1:]
    if not len(lines):
      return

    for index, line in enumerate(lines):
      if not len(line):
        lines[index] = '\n'

    text = ' '.join(lines)
    if tag is None or tag == 'brief':
      if self.doc.main:
        self.doc.main += '\n'
      self.doc.main += text
    else:
      self.doc.tags.append((tag, text))
