"use client";

import { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";

const CANVAS_W = 1080;
const CANVAS_H = 1920;
const SOURCE_CROP_TOP = 180;
const SOURCE_W = 1290;
const SOURCE_H = 2796;

const slides = [
  {
    id: "home",
    image: "/screenshots/android/phone/ko/01-home.png",
    eyebrow: "Clib",
    headline: ["읽어야 했던 링크들", "밀어서 해치우세요"],
    subcopy: "스와이프로 읽기 시작",
    accentWord: "해치우세요",
    phone: { top: 360, rotate: 0, scale: 1 },
  },
  {
    id: "swipe",
    image: "/screenshots/android/phone/ko/02-swipe.png",
    eyebrow: "Swipe",
    headline: ["읽음 / 나중에", "스와이프로 끝"],
    subcopy: "밀린 콘텐츠를 빠르게 분류",
    accentWord: "스와이프로",
    phone: { top: 364, rotate: 0, scale: 1.04 },
  },
  {
    id: "library",
    image: "/screenshots/android/phone/ko/03-library.png",
    eyebrow: "Library",
    headline: ["안 읽은 것만", "바로 확인"],
    subcopy: "보관함에서 읽기 현황 확인",
    accentWord: "바로 확인",
    phone: { top: 360, rotate: 0, scale: 1 },
  },
  {
    id: "labels",
    image: "/screenshots/android/phone/ko/04-labels.png",
    eyebrow: "Labels",
    headline: ["관심사끼리", "따로 모으세요"],
    subcopy: "라벨로 정리하면 깔끔",
    accentWord: "모으세요",
    phone: { top: 360, rotate: 0, scale: 1 },
  },
  {
    id: "reminders",
    image: "/screenshots/android/phone/ko/05-reminders.png",
    eyebrow: "Reminder",
    headline: ["안 읽으면", "알려드릴게요"],
    subcopy: "요일별 읽기 알림",
    accentWord: "알려드릴게요",
    phone: { top: 360, rotate: 0, scale: 1 },
  },
] as const;

const imagePaths = [
  "/app-icon.png",
  ...slides.map((slide) => slide.image),
];

function splitHeadline(lines: readonly string[], accentWord: string) {
  return lines.map((line, index) => {
    const parts = line.split(accentWord);
    return (
      <span key={line}>
        {parts.length === 1 ? (
          line
        ) : (
          <>
            {parts[0]}
            <span className="text-[#7bd2a2]">{accentWord}</span>
            {parts[1]}
          </>
        )}
        {index < lines.length - 1 ? <br /> : null}
      </span>
    );
  });
}

function ScreenshotCanvas({
  slide,
  imageCache,
}: {
  slide: (typeof slides)[number];
  imageCache: Record<string, string>;
}) {
  const imageSrc = imageCache[slide.image] ?? slide.image;
  const iconSrc = imageCache["/app-icon.png"] ?? "/app-icon.png";
  const phoneWidth = 660 * slide.phone.scale;
  const phoneHeight = phoneWidth * ((SOURCE_H - SOURCE_CROP_TOP) / SOURCE_W);
  const imageHeight = phoneHeight * (SOURCE_H / (SOURCE_H - SOURCE_CROP_TOP));
  const imageOffset = phoneHeight * (SOURCE_CROP_TOP / (SOURCE_H - SOURCE_CROP_TOP));

  return (
    <section
      className="relative overflow-hidden bg-[#171818] text-white"
      style={{ width: CANVAS_W, height: CANVAS_H }}
    >
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_12%,rgba(123,210,162,0.18),transparent_30%),linear-gradient(180deg,#1d1d1f_0%,#101112_100%)]" />
      <div className="absolute left-[72px] right-[72px] top-[64px] flex items-center justify-between">
        <div className="flex items-center gap-[20px]">
          <img
            alt=""
            className="h-[72px] w-[72px] rounded-[18px] shadow-[0_20px_50px_rgba(0,0,0,0.4)]"
            draggable={false}
            src={iconSrc}
          />
          <div className="text-[30px] font-bold uppercase tracking-[0.16em] text-[#7bd2a2]">
            {slide.eyebrow}
          </div>
        </div>
      </div>

      <div className="absolute left-0 right-0 top-[116px] text-center">
        <h1 className="text-[72px] font-extrabold leading-[0.98] tracking-normal">
          {splitHeadline(slide.headline, slide.accentWord)}
        </h1>
        <p className="mt-[26px] text-[28px] font-bold text-white/48">
          {slide.subcopy}
        </p>
      </div>

      <div
        className="absolute left-1/2 rounded-[64px] bg-[#202123] p-10 shadow-[0_42px_90px_rgba(0,0,0,0.52)]"
        style={{
          top: slide.phone.top,
          width: phoneWidth + 20,
          height: phoneHeight + 20,
          transform: `translateX(-50%) rotate(${slide.phone.rotate}deg)`,
        }}
      >
        <div className="h-full w-full overflow-hidden rounded-[54px] bg-black">
          <img
            alt=""
            className="block w-full object-cover object-top"
            draggable={false}
            style={{ height: imageHeight, transform: `translateY(-${imageOffset}px)` }}
            src={imageSrc}
          />
        </div>
      </div>

      <div className="absolute bottom-[42px] left-1/2 h-[6px] w-[180px] -translate-x-1/2 rounded-full bg-[#7bd2a2]/70" />
    </section>
  );
}

function Preview({
  index,
  slide,
  imageCache,
  setRef,
}: {
  index: number;
  slide: (typeof slides)[number];
  imageCache: Record<string, string>;
  setRef: (index: number, el: HTMLElement | null) => void;
}) {
  return (
    <div className="rounded-lg border border-white/10 bg-[#202124] p-3">
      <div className="mb-3 flex items-center justify-between text-sm text-white/70">
        <span>
          {String(index + 1).padStart(2, "0")} / {slide.id}
        </span>
        <span>1080x1920</span>
      </div>
      <div className="h-[640px] overflow-hidden rounded-md bg-black">
        <div
          style={{
            height: CANVAS_H,
            transform: "scale(0.333333)",
            transformOrigin: "top left",
            width: CANVAS_W,
          }}
        >
          <ScreenshotCanvas imageCache={imageCache} slide={slide} />
        </div>
      </div>
      <div
        aria-hidden
        className="pointer-events-none absolute left-[-9999px] top-0"
        ref={(el) => setRef(index, el)}
      >
        <ScreenshotCanvas imageCache={imageCache} slide={slide} />
      </div>
    </div>
  );
}

async function preloadImages() {
  const cache: Record<string, string> = {};
  await Promise.all(
    imagePaths.map(async (path) => {
      const response = await fetch(path);
      const blob = await response.blob();
      cache[path] = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
      });
    }),
  );
  return cache;
}

export default function PlayStoreScreenshots() {
  const exportRefs = useRef<(HTMLElement | null)[]>([]);
  const [imageCache, setImageCache] = useState<Record<string, string>>({});
  const [ready, setReady] = useState(false);
  const [exporting, setExporting] = useState<string | null>(null);

  useEffect(() => {
    preloadImages().then((cache) => {
      setImageCache(cache);
      setReady(true);
    });
  }, []);

  async function exportAll() {
    for (let index = 0; index < slides.length; index += 1) {
      const el = exportRefs.current[index];
      if (!el) continue;
      setExporting(`${index + 1}/${slides.length}`);
      el.style.left = "0px";
      await toPng(el, { width: CANVAS_W, height: CANVAS_H, pixelRatio: 1, cacheBust: true });
      const dataUrl = await toPng(el, { width: CANVAS_W, height: CANVAS_H, pixelRatio: 1, cacheBust: true });
      el.style.left = "-9999px";
      const anchor = document.createElement("a");
      anchor.href = dataUrl;
      anchor.download = `${String(index + 1).padStart(2, "0")}-${slides[index].id}-ko-1080x1920.png`;
      anchor.click();
      await new Promise((resolve) => setTimeout(resolve, 300));
    }
    setExporting(null);
  }

  return (
    <main className="min-h-screen overflow-x-hidden bg-[#111213] text-white">
      <div className="sticky top-0 z-20 flex items-center justify-between border-b border-white/10 bg-[#111213]/95 px-6 py-4 backdrop-blur">
        <div>
          <h1 className="text-lg font-bold">Clib Google Play Screenshots</h1>
          <p className="text-sm text-white/50">Phone portrait / Korean / 1080x1920</p>
        </div>
        <button
          className="rounded-md bg-[#7bd2a2] px-5 py-2 text-sm font-bold text-[#101112] disabled:opacity-50"
          disabled={!ready || !!exporting}
          onClick={exportAll}
        >
          {exporting ? `Exporting ${exporting}` : "Export All"}
        </button>
      </div>

      {!ready ? (
        <div className="p-8 text-white/60">Loading images...</div>
      ) : (
        <div className="grid gap-6 p-6 md:grid-cols-2 xl:grid-cols-3">
          {slides.map((slide, index) => (
            <Preview
              imageCache={imageCache}
              index={index}
              key={slide.id}
              setRef={(refIndex, el) => {
                exportRefs.current[refIndex] = el;
              }}
              slide={slide}
            />
          ))}
        </div>
      )}
    </main>
  );
}
