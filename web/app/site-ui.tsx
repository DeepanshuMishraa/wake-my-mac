"use client";

import { useId, useRef, useState } from "react";

export const downloadUrl =
  "https://pub-0f452c90e334438d8e4a54f9b977a5ea.r2.dev/Wake-My-Mac-0.0.3.dmg";

const quarantineCommand =
  'sudo xattr -rd com.apple.quarantine "/Applications/Wake My Mac.app"';

export function AppleIcon() {
  return (
    <svg viewBox="0 0 814 1000" aria-hidden="true">
      <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z" />
    </svg>
  );
}

function DownloadArrowIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M4 12h16m0 0-6-6m6 6-6 6" />
    </svg>
  );
}

function LockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="5" y="10" width="14" height="11" rx="3" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </svg>
  );
}

function BackIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="m10 6-6 6 6 6M4 12h16" />
    </svg>
  );
}

export function GitHubIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 .7a11.5 11.5 0 0 0-3.64 22.41c.58.1.79-.25.79-.56v-2.23c-3.23.7-3.91-1.37-3.91-1.37-.53-1.34-1.29-1.7-1.29-1.7-1.05-.72.08-.71.08-.71 1.17.08 1.78 1.2 1.78 1.2 1.04 1.78 2.72 1.27 3.38.97.1-.75.4-1.27.74-1.56-2.58-.29-5.29-1.29-5.29-5.69 0-1.26.45-2.28 1.19-3.09-.12-.29-.52-1.47.11-3.05 0 0 .97-.31 3.16 1.18a10.96 10.96 0 0 1 5.76 0c2.2-1.49 3.16-1.18 3.16-1.18.63 1.58.23 2.76.11 3.05.74.81 1.19 1.83 1.19 3.09 0 4.41-2.72 5.39-5.3 5.68.42.36.79 1.07.79 2.16v3.21c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .7Z" />
    </svg>
  );
}

function XIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M18.9 2H22l-6.77 7.74L23.2 22h-6.24l-4.89-6.39L6.48 22H3.36l7.26-8.3L2.97 2H9.4l4.42 5.84L18.9 2Zm-1.1 17.84h1.73L8.46 4.05H6.6L17.8 19.84Z" />
    </svg>
  );
}

function LinkedInIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5.34 7.67H1.68V22h3.66V7.67ZM3.51 2A2.13 2.13 0 1 0 3.5 6.25 2.13 2.13 0 0 0 3.51 2ZM22.32 13.78c0-4.32-2.3-6.33-5.38-6.33a4.65 4.65 0 0 0-4.21 2.32v-2.1H9.07V22h3.66v-7.1c0-1.87.36-3.69 2.68-3.69 2.29 0 2.32 2.14 2.32 3.81V22h3.66l.93-8.22Z" />
    </svg>
  );
}

export function DownloadLink({ className }: { className: string }) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const descriptionId = useId();
  const [copyState, setCopyState] = useState<"idle" | "copied" | "error">(
    "idle",
  );

  function openDownloadDialog() {
    setCopyState("idle");
    dialogRef.current?.showModal();
  }

  function closeDownloadDialog() {
    dialogRef.current?.close();
  }

  async function copyCommand() {
    try {
      await navigator.clipboard.writeText(quarantineCommand);
      setCopyState("copied");
    } catch {
      setCopyState("error");
    }
  }

  return (
    <>
      <a
        className={className}
        href={downloadUrl}
        onClick={(event) => {
          event.preventDefault();
          openDownloadDialog();
        }}
      >
        <span className="download-leading"><AppleIcon /></span>
        <span className="download-label">
          <span className="download-full">Download for Mac</span>
          <span className="download-short">Download</span>
        </span>
        <span className="download-trailing"><DownloadArrowIcon /></span>
      </a>

      <dialog
        className="download-dialog"
        ref={dialogRef}
        aria-labelledby={titleId}
        aria-describedby={descriptionId}
        onClick={(event) => {
          if (event.target === event.currentTarget) {
            closeDownloadDialog();
          }
        }}
        onClose={() => setCopyState("idle")}
      >
        <div className="download-dialog-panel">
          <button
            className="dialog-close"
            type="button"
            onClick={closeDownloadDialog}
            aria-label="Close download dialog"
          >
            ×
          </button>

          <span className="dialog-icon" aria-hidden="true">
            <AppleIcon />
          </span>
          <p className="dialog-kicker">Before you download</p>
          <h2 id={titleId}>Wake My Mac isn’t signed by Apple yet.</h2>
          <p className="dialog-copy" id={descriptionId}>
            macOS may block the first launch. Download the app, move it to
            Applications, then run this command in Terminal to remove the
            quarantine flag.
          </p>

          <div className="command-copy">
            <code>{quarantineCommand}</code>
            <button type="button" onClick={copyCommand}>
              {copyState === "copied"
                ? "Copied"
                : copyState === "error"
                  ? "Copy failed"
                  : "Copy"}
            </button>
          </div>

          <p className="dialog-note">
            Only run commands you understand. This command targets Wake My Mac
            in your Applications folder.
          </p>

          <a
            className="dialog-download"
            href={downloadUrl}
            onClick={closeDownloadDialog}
          >
            Download Wake My Mac <DownloadArrowIcon />
          </a>
        </div>
      </dialog>
    </>
  );
}

export function Brand({ iconAction }: { iconAction: "home" | "privacy" }) {
  const linksToPrivacy = iconAction === "privacy";

  return (
    <div className="brand">
      <a
        className="brand-icon-link"
        href={linksToPrivacy ? "/privacy" : "/"}
        aria-label={linksToPrivacy ? "Read our privacy policy" : "Back to Wake My Mac"}
      >
        <span className="brand-mark" aria-hidden="true">
          <span className="brand-idle" />
          <span className="brand-reveal">
            {linksToPrivacy ? <LockIcon /> : <BackIcon />}
          </span>
        </span>
      </a>
      <a className="brand-name" href="/">Wake My Mac</a>
      <span className="version">v0.0.3</span>
    </div>
  );
}

export function SocialLinks() {
  return (
    <div className="social-links" aria-label="Project links">
      <a
        href="https://github.com/DeepanshuMishraa/wake-my-mac"
        aria-label="Wake My Mac on GitHub"
      >
        <GitHubIcon />
      </a>
      <a href="https://x.com/dipxsyy" aria-label="Dipxsy on X">
        <XIcon />
      </a>
      <a
        href="https://linkedin.com/in/deepanshum"
        aria-label="Deepanshum on LinkedIn"
      >
        <LinkedInIcon />
      </a>
    </div>
  );
}
