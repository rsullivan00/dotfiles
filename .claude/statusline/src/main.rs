//! Claude Code status line — compact, colorful. Rust port for fast cold-start.
//! Reads Claude's status JSON from stdin and writes two ANSI-coloured lines.

use std::io::{self, Read, Write};

use serde_json::Value;

fn fmt_num(n: i64) -> String {
    if n >= 1_000_000 {
        format!("{:.2}M", n as f64 / 1_000_000.0)
    } else if n >= 1_000 {
        format!("{:.1}K", n as f64 / 1_000.0)
    } else {
        n.to_string()
    }
}

fn i64_at(v: &Value, k: &str) -> i64 {
    v.get(k).and_then(Value::as_i64).unwrap_or(0)
}

fn f64_at(v: &Value, k: &str) -> f64 {
    v.get(k).and_then(Value::as_f64).unwrap_or(0.0)
}

fn main() -> io::Result<()> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    let data: Value = serde_json::from_str(&input).unwrap_or(Value::Null);

    let ctx = &data["context_window"];
    let usage = &ctx["current_usage"];

    let total_input = i64_at(ctx, "total_input_tokens");
    let total_output = i64_at(ctx, "total_output_tokens");
    let cache_create = i64_at(usage, "cache_creation_input_tokens");
    let cache_read = i64_at(usage, "cache_read_input_tokens");
    let ctx_size = ctx
        .get("context_window_size")
        .and_then(Value::as_i64)
        .unwrap_or(200_000);
    let used_pct = f64_at(ctx, "used_percentage");
    let session_cost = f64_at(&data["cost"], "total_cost_usd");
    let model_name = data["model"]["display_name"]
        .as_str()
        .unwrap_or("Unknown");

    // ANSI colours
    const R: &str = "\x1b[0m";
    const DIM: &str = "\x1b[2m";
    const GRN: &str = "\x1b[32m";
    const BGRN: &str = "\x1b[92m";
    const BBLU: &str = "\x1b[94m";
    const YEL: &str = "\x1b[33m";
    const BYEL: &str = "\x1b[93m";
    const BMAG: &str = "\x1b[95m";
    const WHT: &str = "\x1b[97m";

    // Dot bar
    let filled = (used_pct * 8.0 / 100.0) as usize;
    let mut dots = String::with_capacity(128);
    for i in 0..8 {
        let colour = if i < filled { BGRN } else { DIM };
        dots.push_str(colour);
        dots.push('\u{25cf}'); // ●
        dots.push_str(R);
    }

    let ctx_used = (ctx_size as f64 * used_pct / 100.0) as i64;
    let total_cached = cache_read + cache_create;
    let grand_total = total_input + total_output + total_cached;

    let stdout = io::stdout();
    let mut out = stdout.lock();

    writeln!(
        out,
        "{BMAG}{model_name}{R} {dots} {BYEL}{used_pct:.1}%{R} {WHT}{ctx_used_fmt}{R}/{DIM}{ctx_size_fmt}{R}  {BGRN}Cost: ${session_cost:.2}{R}",
        ctx_used_fmt = fmt_num(ctx_used),
        ctx_size_fmt = fmt_num(ctx_size),
    )?;

    writeln!(
        out,
        "{GRN}In:{R} {WHT}{in_fmt}{R}  {BBLU}Out:{R} {WHT}{out_fmt}{R}  {YEL}Cache:{R} {WHT}{cache_fmt}{R}  {BMAG}Total:{R} {WHT}{total_fmt}{R}",
        in_fmt = fmt_num(total_input),
        out_fmt = fmt_num(total_output),
        cache_fmt = fmt_num(total_cached),
        total_fmt = fmt_num(grand_total),
    )?;

    Ok(())
}
