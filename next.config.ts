import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  agentRules: false,
  output: "standalone",
  reactCompiler: true,
};

export default nextConfig;
