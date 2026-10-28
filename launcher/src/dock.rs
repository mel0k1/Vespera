//! Vespera's floating dock: the pages, the account chip and Settings on a translucent plate
//! that hovers over the bottom of the content area. It replaces Horizon's top bar (kept in
//! `main.rs` so upstream edits still merge); this file is Vespera's own.

use super::*;

/// The dock's height, in logical pixels.
const HEIGHT: f32 = 56.;
/// The plate's corner rounding. Blocks have square corners; the dock alone is rounded, because
/// it floats over live content and reads as above the page rather than part of it.
const PLATE: f32 = 14.;
/// The rounding of the pills inside it, one step quieter.
const PILL: f32 = 10.;

impl Launcher {
    /// The dock at the bottom of the content area: the wordmark (where the title bar doesn't
    /// carry it), the page tabs, then the account chip and Settings.
    pub(super) fn dock(&mut self, window: &Window, cx: &mut Context<Self>) -> Div {
        let t = self.theme;
        let mut nav = div().flex().flex_none().items_center().gap(px(4.));
        for (page, label, icon) in Page::ALL {
            if page == Page::Settings {
                continue;
            }
            let active = self.page == page;
            let id = SharedString::from(format!("nav-{label}"));
            let item = div()
                .id(id.clone())
                .relative()
                .flex()
                .items_center()
                .gap(px(8.))
                .px(px(12.))
                .h(px(40.))
                .rounded(px(PILL))
                .cursor_pointer()
                .when(active, |d| {
                    d.bg(t.raised).child(
                        div()
                            .absolute()
                            .left(px(10.))
                            .right(px(10.))
                            .top_0()
                            .h(px(4.))
                            .rounded(px(2.))
                            .bg(t.accent),
                    )
                })
                .when(!active, |d| d.child(hover_layer(&id, t.raised, PILL, 0.)))
                .child(div().relative().child(blocks::icon(
                    icon,
                    18.,
                    if active { t.accent } else { t.muted },
                )))
                .child(
                    blocks::pixel(15., FontWeight::MEDIUM)
                        .relative()
                        .text_color(if active { t.ink } else { t.muted })
                        .child(tr(label)),
                )
                .on_click(cx.listener(move |this, _: &ClickEvent, _, cx| {
                    this.go(page);
                    cx.notify();
                }));
            nav = nav.child(keyboard(track_hover(item, id), &t));
        }
        // Only a signed-in account says "Microsoft account"; otherwise an offline name, or the
        // one the game made up.
        let (name, how) = self.who_plays();
        let account = keyboard(div().id("account"), &t)
            .relative()
            .flex()
            .min_w_0()
            .max_w(px(200.))
            .items_center()
            .gap(px(10.))
            .h(px(40.))
            .pl(px(4.))
            .pr(px(12.))
            .rounded(px(PILL))
            .bg(t.panel)
            .border_2()
            .border_color(t.outline)
            .cursor_pointer()
            .hover(move |s| s.bg(t.raised))
            .child(
                div()
                    .flex()
                    .items_center()
                    .justify_center()
                    .size(px(30.))
                    .rounded(px(PILL - 2.))
                    .bg(t.well)
                    .child(blocks::icon("user", 18., t.muted)),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .min_w_0()
                    .child(
                        blocks::pixel(14., FontWeight::MEDIUM)
                            .truncate()
                            .text_color(t.ink)
                            .child(name),
                    )
                    .child(text(theme::CAPTION).text_color(t.muted).child(how)),
            )
            .on_click(cx.listener(|this, _: &ClickEvent, _, cx| {
                this.account_menu = !this.account_menu;
                cx.notify();
            }));
        let account = div()
            .relative()
            .child(account)
            .children(self.account_menu(cx));
        let settings_open = self.page == Page::Settings;
        let settings = keyboard(div().id("nav-Settings"), &t)
            .relative()
            .flex()
            .items_center()
            .justify_center()
            .size(px(40.))
            .rounded(px(PILL))
            .bg(if settings_open { t.raised } else { t.panel })
            .border_2()
            .border_color(t.outline)
            .cursor_pointer()
            .hover(move |s| s.bg(t.raised))
            .when(settings_open, |d| {
                d.child(
                    div()
                        .absolute()
                        .left(px(10.))
                        .right(px(10.))
                        .top_0()
                        .h(px(4.))
                        .rounded(px(2.))
                        .bg(t.accent),
                )
            })
            .child(blocks::icon(
                "sliders",
                20.,
                if settings_open { t.accent } else { t.ink_soft },
            ))
            .on_click(cx.listener(|this, _: &ClickEvent, _, cx| {
                this.go(Page::Settings);
                cx.notify();
            }));
        // The plate: translucent, so the page scrolls under it; a soft shadow lifts it off the
        // content. The shadow colour follows the theme's outline, so it stays a shade of the
        // palette in both appearances.
        let lift = |dy: f32, blur: f32, spread: f32, a: f32| gpui::BoxShadow {
            color: t.outline.opacity(a),
            offset: gpui::point(px(0.), px(dy)),
            blur_radius: px(blur),
            spread_radius: px(spread),
        };
        div()
            .absolute()
            .left(px(16.))
            .right(px(16.))
            .bottom(px(14.))
            .flex()
            .child(
                div()
                    .flex()
                    .items_center()
                    .w_full()
                    .h(px(HEIGHT))
                    .pl(px(12.))
                    .pr(px(8.))
                    .gap(px(8.))
                    .bg(t.panel.opacity(0.85))
                    .border_2()
                    .border_color(t.outline)
                    .rounded(px(PLATE))
                    .shadow(vec![lift(10., 28., -6., 0.42), lift(2., 8., -2., 0.30)])
                    // Custom title bars carry the mark and name above the sidebar.
                    .when(!titlebar::draws_brand(window), |bar| {
                        bar.child(mark(18., &t))
                            .child(
                                blocks::pixel(15., FontWeight::SEMIBOLD)
                                    .text_color(t.ink)
                                    .child("VESPERA"),
                            )
                            .child(div().w(px(1.)).h(px(26.)).mx(px(6.)).bg(t.rule))
                    })
                    .child(nav)
                    .child(
                        div()
                            .ml_auto()
                            .flex()
                            .flex_none()
                            .items_center()
                            .gap(px(8.))
                            .child(account)
                            .child(settings),
                    ),
            )
    }
}
