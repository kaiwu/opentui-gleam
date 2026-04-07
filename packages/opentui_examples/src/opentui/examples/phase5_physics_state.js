export function createWorldHolder() {
  return { world: null };
}

export function getWorld(holder) {
  return holder.world;
}

export function setWorld(holder, world) {
  holder.world = world;
}
