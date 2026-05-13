import { useEffect, useRef, useState } from 'react';
import { useBackend } from '../backend';

type Frame = {
  url: string;
  delay_ms: number;
};

type Layer = {
  frames: Frame[];
  color: string;
  alpha: number;
  pixelY?: number;
};

type Data = {
  visible: boolean;
  layers?: Layer[];
};

// BYOND pixel_y values are computed against a 960-tall fullscreen image.
// We scale to the overlay's actual height with translateY in % of the image
// space (negative pixel_y moves down per BYOND convention; mirror that).
const BYOND_FULLSCREEN_PX = 960;

// Each layer paints the icon's RGB content tinted by L.color, mirroring
// BYOND's `color = "#xxx"` semantic on an /image overlay: per-pixel
// multiply against the tint, alpha preserved.
//
// We achieve this with two CSS effects combined:
//   1. background: url(icon) over a solid tint, blend-mode multiply.
//      This multiplies the icon's RGB by the tint where the icon is
//      opaque, but leaves the solid tint visible where the icon is
//      transparent (wrong).
//   2. mask-image: url(icon) with mask-mode: alpha. This clips the
//      entire layer to the icon's alpha shape, dropping the unwanted
//      solid tint in transparent areas (right).
const frameStyle = (
  L: Layer,
  url: string,
  active: boolean,
): React.CSSProperties => {
  const pct = ((L.pixelY ?? 0) / BYOND_FULLSCREEN_PX) * 100;
  return {
    position: 'fixed',
    inset: 0,
    width: '100%',
    height: '100%',
    backgroundImage: `url(${url})`,
    backgroundSize: '100% 100%',
    backgroundRepeat: 'no-repeat',
    backgroundColor: L.color,
    backgroundBlendMode: 'multiply',
    WebkitMaskImage: `url(${url})`,
    maskImage: `url(${url})`,
    WebkitMaskRepeat: 'no-repeat',
    maskRepeat: 'no-repeat',
    WebkitMaskSize: '100% 100%',
    maskSize: '100% 100%',
    WebkitMaskMode: 'alpha',
    maskMode: 'alpha',
    opacity: active ? L.alpha / 255 : 0,
    transform: pct ? `translateY(${-pct}%)` : undefined,
    pointerEvents: 'none',
  };
};

// Aggressive background reset. We bypass tgui's <Pane>/<Layout> chrome
// entirely — those apply theme-driven gradients, NT-logo SVG, etc., that
// paint opaque pixels and ruin the BROWSER widget's transparency. We
// also have to zero out html/body/#react-root because the framework
// still mounts our component inside them.
const RESET_CSS = `
html, body, #react-root, .BellyOverlayRoot,
div[class^="theme-"], .Layout, .Layout__content, .Window {
  background: transparent !important;
  background-image: none !important;
  margin: 0 !important;
  padding: 0 !important;
  border: 0 !important;
  overflow: hidden !important;
}
html, body, #react-root, .BellyOverlayRoot {
  width: 100% !important;
  height: 100% !important;
  position: fixed !important;
  inset: 0 !important;
}
`;

// One animated layer: renders every frame as a stacked sibling, toggling
// opacity so only the active frame paints. This avoids the URL-swap
// flicker you get from rewriting background-image on a single node — the
// browser keeps every frame decoded after the first paint.
const LayerView = ({ L, layerKey }: { L: Layer; layerKey: string }) => {
  const frames = L.frames || [];
  const [idx, setIdx] = useState(0);
  const idxRef = useRef(0);
  idxRef.current = idx;
  useEffect(() => {
    if (frames.length <= 1) {
      return;
    }
    let cancelled = false;
    let timeoutId: ReturnType<typeof setTimeout> | undefined;
    const schedule = () => {
      if (cancelled) {
        return;
      }
      const current = idxRef.current;
      const delay = Math.max(20, frames[current]?.delay_ms ?? 100);
      timeoutId = setTimeout(() => {
        if (cancelled) {
          return;
        }
        const next = (current + 1) % frames.length;
        idxRef.current = next;
        setIdx(next);
        schedule();
      }, delay);
    };
    schedule();
    return () => {
      cancelled = true;
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
    };
  }, [layerKey, frames.length]);
  if (frames.length === 0) {
    return null;
  }
  return (
    <>
      {frames.map((F, i) => (
        <div
          key={`${layerKey}:${i}`}
          style={frameStyle(L, F.url, i === idx)}
        />
      ))}
    </>
  );
};

export const BellyOverlay = (_props) => {
  const { data } = useBackend<Data>();
  const layers = data.layers || [];
  return (
    <div className="BellyOverlayRoot">
      <style>{RESET_CSS}</style>
      {data.visible &&
        layers.map((L, i) => {
          const first = L.frames?.[0]?.url ?? '';
          const key = `${i}:${first}`;
          return <LayerView key={key} L={L} layerKey={key} />;
        })}
    </div>
  );
};
