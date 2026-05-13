import { useBackend } from '../backend';
import { Pane } from '../layouts';

type Layer = {
  url: string;
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

const layerStyle = (L: Layer): React.CSSProperties => {
  const pct = ((L.pixelY ?? 0) / BYOND_FULLSCREEN_PX) * 100;
  return {
    position: 'fixed',
    inset: 0,
    width: '100%',
    height: '100%',
    backgroundColor: L.color,
    opacity: L.alpha / 255,
    WebkitMaskImage: `url(${L.url})`,
    maskImage: `url(${L.url})`,
    WebkitMaskRepeat: 'no-repeat',
    maskRepeat: 'no-repeat',
    WebkitMaskSize: '100% 100%',
    maskSize: '100% 100%',
    WebkitMaskMode: 'alpha',
    maskMode: 'alpha',
    transform: pct ? `translateY(${-pct}%)` : undefined,
    pointerEvents: 'none',
  };
};

export const BellyOverlay = (_props) => {
  const { data } = useBackend<Data>();
  const layers = data.layers || [];
  if (!data.visible || layers.length === 0) {
    return <Pane className="BellyOverlayPane" />;
  }
  return (
    <Pane className="BellyOverlayPane">
      <style>
        {`html, body, #react-root, .BellyOverlayPane, .Layout, .Layout__content {
          background: transparent !important;
          background-color: transparent !important;
          margin: 0; padding: 0;
          width: 100%; height: 100%;
          overflow: hidden;
        }`}
      </style>
      {layers.map((L, i) => (
        <div key={i} style={layerStyle(L)} />
      ))}
    </Pane>
  );
};
