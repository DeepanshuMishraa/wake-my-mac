import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  poweredByHeader: false,
  compress: true,
  async redirects() {
    return [
      {
        source: "/:path*",
        has: [{ type: "host", value: "wakemymac.dipxsy.app" }],
        destination: "https://stayrunning.dipxsy.app/:path*",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
