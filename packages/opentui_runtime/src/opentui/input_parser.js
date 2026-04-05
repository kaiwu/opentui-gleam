const INPUT_TIMEOUT_MS = 20;

function utf8CharLength(byte) {
  if (byte < 0x80) return 1;
  if (byte >= 0xc2 && byte <= 0xdf) return 2;
  if (byte >= 0xe0 && byte <= 0xef) return 3;
  if (byte >= 0xf0 && byte <= 0xf4) return 4;
  return 0;
}

function scanEscTerminatedSequence(buffer, start) {
  let i = start + 2;

  while (i < buffer.length) {
    if (buffer[i] === 0x07) return i + 1;
    if (buffer[i] === 0x1b) {
      if (i + 1 >= buffer.length) return -1;
      if (buffer[i + 1] === 0x5c) return i + 2;
    }
    i += 1;
  }

  return -1;
}

function scanCsiSequence(buffer, start) {
  let i = start + 2;

  while (i < buffer.length) {
    const byte = buffer[i];
    if (byte >= 0x40 && byte <= 0x7e) return i + 1;
    i += 1;
  }

  return -1;
}

function parseInputToken(buffer, start) {
  const byte = buffer[start];

  if (byte === 0x03) return { next: start + 1, token: "\x03" };
  if (byte === 0x0d || byte === 0x0a) return { next: start + 1, token: "\n" };
  if (byte === 0x08 || byte === 0x7f) return { next: start + 1, token: "\x7f" };

  if (byte === 0x1b) {
    if (start + 1 >= buffer.length) return null;
    const nextByte = buffer[start + 1];

    if (nextByte === 0x4f) {
      if (start + 2 >= buffer.length) return null;
      switch (buffer[start + 2]) {
        case 0x41: return { next: start + 3, token: "\x1b[A" };
        case 0x42: return { next: start + 3, token: "\x1b[B" };
        case 0x43: return { next: start + 3, token: "\x1b[C" };
        case 0x44: return { next: start + 3, token: "\x1b[D" };
        default: return { next: start + 3, token: null };
      }
    }

    if (nextByte === 0x5b) {
      const end = scanCsiSequence(buffer, start);
      if (end === -1) return null;
      const finalByte = buffer[end - 1];
      if (finalByte === 0x41) return { next: end, token: "\x1b[A" };
      if (finalByte === 0x42) return { next: end, token: "\x1b[B" };
      if (finalByte === 0x43) return { next: end, token: "\x1b[C" };
      if (finalByte === 0x44) return { next: end, token: "\x1b[D" };
      return { next: end, token: buffer.subarray(start, end).toString("utf-8") };
    }

    if (nextByte === 0x5d || nextByte === 0x50 || nextByte === 0x5f || nextByte === 0x5e) {
      const end = scanEscTerminatedSequence(buffer, start);
      if (end === -1) return null;
      return { next: end, token: null };
    }

    if (nextByte >= 0x20 && nextByte <= 0x7e) {
      return { next: start + 2, token: String.fromCharCode(nextByte) };
    }

    return { next: start + 2, token: null };
  }

  if (byte < 0x20) return { next: start + 1, token: null };
  if (byte < 0x80) return { next: start + 1, token: String.fromCharCode(byte) };

  const charLength = utf8CharLength(byte);
  if (charLength === 0) return { next: start + 1, token: null };
  if (start + charLength > buffer.length) return null;

  return {
    next: start + charLength,
    token: buffer.subarray(start, start + charLength).toString("utf-8"),
  };
}

export function createParser() {
  return { pending: Buffer.alloc(0), flushTimer: null };
}

function collectTokens(parser, chunk) {
  const incoming = Buffer.from(chunk, "utf-8");
  parser.pending = parser.pending.length === 0 ? incoming : Buffer.concat([parser.pending, incoming]);

  if (parser.flushTimer !== null) {
    clearTimeout(parser.flushTimer);
    parser.flushTimer = null;
  }

  let offset = 0;
  const tokens = [];

  while (offset < parser.pending.length) {
    const parsed = parseInputToken(parser.pending, offset);
    if (parsed === null) break;
    offset = parsed.next;
    if (parsed.token !== null) tokens.push(parsed.token);
  }

  parser.pending = offset === 0 ? parser.pending : parser.pending.subarray(offset);

  if (parser.pending.length > 0) {
    parser.flushTimer = setTimeout(() => {
      parser.pending = Buffer.alloc(0);
      parser.flushTimer = null;
    }, INPUT_TIMEOUT_MS);
  }

  return tokens;
}

export function consumeChunk(parser, chunk, onToken) {
  for (const token of collectTokens(parser, chunk)) {
    onToken(token);
  }
}

export function pushChunkJoined(parser, chunk) {
  return collectTokens(parser, chunk).join("\x1f");
}
