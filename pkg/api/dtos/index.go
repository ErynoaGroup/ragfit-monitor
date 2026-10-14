// Modified by ErynoaGroup, 2026-10-14: Erynoa header fields (base domain, skip link target).

package dtos

import (
	"html/template"

	"github.com/grafana/grafana/pkg/services/navtree"
)

type IndexViewData struct {
	User                                *CurrentUser         `json:"user"`
	Settings                            *FrontendSettingsDTO `json:"settings"`
	AppUrl                              string               `json:"-"`
	AppSubUrl                           string               `json:"-"`
	GoogleAnalyticsId                   string               `json:"-"`
	GoogleAnalytics4Id                  string               `json:"-"`
	GoogleAnalytics4SendManualPageViews bool                 `json:"-"`
	GoogleTagManagerId                  string               `json:"-"`
	NavTree                             *navtree.NavTreeRoot `json:"navTree"`
	BuildVersion                        string               `json:"-"`
	BuildCommit                         string               `json:"-"`
	ThemeType                           string               `json:"-"`
	NewGrafanaVersionExists             bool                 `json:"-"`
	NewGrafanaVersion                   string               `json:"-"`
	AppName                             string               `json:"-"`
	AppNameBodyClass                    string               `json:"-"`
	FavIcon                             template.URL         `json:"-"`
	AppleTouchIcon                      template.URL         `json:"-"`
	AppTitle                            string               `json:"-"`
	LoadingLogo                         template.URL         `json:"-"`
	CSPContent                          string               `json:"-"`
	CSPEnabled                          bool                 `json:"-"`
	IsDevelopmentEnv                    bool                 `json:"-"`
	// Nonce is a cryptographic identifier for use with Content Security Policy.
	Nonce                  string            `json:"-"`
	NewsFeedEnabled        bool              `json:"-"`
	Assets                 *EntryPointAssets `json:"assets"` // Includes CDN info
	RenderBindingSupported bool              `json:"-"`
	UseLuxon               bool              `json:"-"`
	// AutoLoginRedirectURL is the URL the frontend should redirect to for auto-login.
	// Empty means no auto-login redirect should occur.
	AutoLoginRedirectURL  string `json:"autoLoginRedirectURL,omitempty"`
	AssetSriChecksEnabled bool   `json:"-"`
	NewPreferencesPage    bool   `json:"-"`
	OFREPRootUrlEnabled   bool   `json:"-"`
	// ErynoaDomain is the base domain for the Erynoa header links: the root_url host minus its
	// first label (monitor.<domain> -> <domain>), resolved at runtime, never stored in the repo.
	ErynoaDomain string `json:"-"`
	// ErynoaSkipHref is the skip link target: the requested path plus #pageContent, because
	// the page's <base href> would otherwise turn a bare fragment into a link to the home page.
	ErynoaSkipHref string `json:"-"`
}

type EntryPointAssets struct {
	ContentDeliveryURL string            `json:"cdn,omitempty"`
	JSFiles            []EntryPointAsset `json:"jsFiles"`
	CSSFiles           []EntryPointAsset `json:"cssFiles"`
	Dark               string            `json:"dark"`
	Light              string            `json:"light"`
}

type EntryPointAsset struct {
	FilePath  string `json:"filePath"`
	Integrity string `json:"integrity"`
}

func (a *EntryPointAssets) SetContentDeliveryURL(prefix string) {
	if prefix == "" {
		return
	}
	a.ContentDeliveryURL = prefix
	a.Dark = prefix + a.Dark
	a.Light = prefix + a.Light
	for i, p := range a.JSFiles {
		a.JSFiles[i].FilePath = prefix + p.FilePath
	}
	for i, p := range a.CSSFiles {
		a.CSSFiles[i].FilePath = prefix + p.FilePath
	}
}
