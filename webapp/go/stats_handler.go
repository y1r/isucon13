package main

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
)

type LivestreamStatistics struct {
	Rank           int64 `json:"rank"`
	ViewersCount   int64 `json:"viewers_count"`
	TotalReactions int64 `json:"total_reactions"`
	TotalReports   int64 `json:"total_reports"`
	MaxTip         int64 `json:"max_tip"`
}

type LivestreamRankingEntry struct {
	LivestreamID int64
	Score        int64
}
type LivestreamRanking []LivestreamRankingEntry

func (r LivestreamRanking) Len() int      { return len(r) }
func (r LivestreamRanking) Swap(i, j int) { r[i], r[j] = r[j], r[i] }
func (r LivestreamRanking) Less(i, j int) bool {
	if r[i].Score == r[j].Score {
		return r[i].LivestreamID < r[j].LivestreamID
	} else {
		return r[i].Score < r[j].Score
	}
}

type UserStatistics struct {
	Rank              int64  `json:"rank"`
	ViewersCount      int64  `json:"viewers_count"`
	TotalReactions    int64  `json:"total_reactions"`
	TotalLivecomments int64  `json:"total_livecomments"`
	TotalTip          int64  `json:"total_tip"`
	FavoriteEmoji     string `json:"favorite_emoji"`
}

type UserRankingEntry struct {
	Username string
	Score    int64
}
type UserRanking []UserRankingEntry

func (r UserRanking) Len() int      { return len(r) }
func (r UserRanking) Swap(i, j int) { r[i], r[j] = r[j], r[i] }
func (r UserRanking) Less(i, j int) bool {
	if r[i].Score == r[j].Score {
		return r[i].Username < r[j].Username
	} else {
		return r[i].Score < r[j].Score
	}
}

func getUserStatisticsHandler(c echo.Context) error {
	ctx := c.Request().Context()

	if err := verifyUserSession(c); err != nil {
		// echo.NewHTTPErrorが返っているのでそのまま出力
		return err
	}

	username := c.Param("username")
	// ユーザごとに、紐づく配信について、累計リアクション数、累計ライブコメント数、累計売上金額を算出
	// また、現在の合計視聴者数もだす

	tx, err := dbConn.BeginTxx(ctx, nil)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "failed to begin transaction: "+err.Error())
	}
	defer tx.Rollback()

	type StatisticsModel struct {
		UserName       string `db:"user_name"`
		ReactionsTotal int64  `db:"reactions_total"`
		Comments       int64  `db:"comments"`
		Tips           int64  `db:"tips"`
		Viewers        int64  `db:"viewers"`
	}

	var statmodels StatisticsModel
	if err := tx.GetContext(
		ctx,
		&statmodels,
		`
		SELECT
		  user_name,
		  reactions_total,
		  comments,
		  tips,
		  viewers
		FROM
		  user_statistics
		WHERE user_name = ?
		`,
		username,
	); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "fail (user_statistics): "+err.Error())
	}

	var rank int64
	if err := tx.GetContext(
		ctx,
		&rank,
		`SELECT COUNT(*)+1 
		FROM user_statistics
		WHERE (reactions_total + tips > ?)
		      OR (reactions_total + tips = ? AND user_name > ?)`,
		statmodels.ReactionsTotal+statmodels.Tips,
		statmodels.ReactionsTotal+statmodels.Tips,
		statmodels.UserName,
	); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "fail (rank): "+err.Error())
	}

	// お気に入り絵文字のためのクエリ文字列
	var query string

	// お気に入り絵文字
	var favoriteEmoji string
	query = `
	SELECT r.emoji_name
	FROM users u
	INNER JOIN livestreams l ON l.user_id = u.id
	INNER JOIN reactions r ON r.livestream_id = l.id
	WHERE u.name = ?
	GROUP BY emoji_name
	ORDER BY COUNT(*) DESC, emoji_name DESC
	LIMIT 1
	`
	if err := tx.GetContext(ctx, &favoriteEmoji, query, username); err != nil && !errors.Is(err, sql.ErrNoRows) {
		return echo.NewHTTPError(http.StatusInternalServerError, "failed to find favorite emoji: "+err.Error())
	}

	stats := UserStatistics{
		Rank:              rank,
		ViewersCount:      statmodels.Viewers,
		TotalReactions:    statmodels.ReactionsTotal,
		TotalLivecomments: statmodels.Comments,
		TotalTip:          statmodels.Tips,
		FavoriteEmoji:     favoriteEmoji,
	}
	return c.JSON(http.StatusOK, stats)
}

func getLivestreamStatisticsHandler(c echo.Context) error {
	ctx := c.Request().Context()

	if err := verifyUserSession(c); err != nil {
		return err
	}

	id, err := strconv.Atoi(c.Param("livestream_id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "livestream_id in path must be integer")
	}
	livestreamID := int64(id)

	tx, err := dbConn.BeginTxx(ctx, nil)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "failed to begin transaction: "+err.Error())
	}
	defer tx.Rollback()

	// 視聴者数算出
	var viewersCount int64
	// 最大チップ額
	var maxTip int64
	// リアクション数
	var totalReactions int64
	// スパム報告数
	var totalReports int64

	type StatisticsModel struct {
		ReactionsTotal int64 `db:"reactions_total"`
		Viewers        int64 `db:"viewers"`
		Reports        int64 `db:"reports"`
		TipsTotal      int64 `db:"tips_total"`
		TipsMax        int64 `db:"tips_max"`
	}

	var statmodels StatisticsModel
	if err := tx.GetContext(
		ctx,
		&statmodels,
		`
		SELECT
		  reactions_total,
		  viewers,
		  reports,
		  tips_total,
		  tips_max
		FROM
		  livestream_statistics
		WHERE livestream_id = ?
		`,
		livestreamID,
	); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "fail (livestream_statistics): "+err.Error())
	}

	viewersCount = statmodels.Viewers
	maxTip = statmodels.TipsMax
	totalReactions = statmodels.ReactionsTotal
	totalReports = statmodels.Reports

	var rank int64
	if err := tx.GetContext(
		ctx,
		&rank,
		`SELECT COUNT(*)+1 
		FROM livestream_statistics
		WHERE (reactions_total + tips_total > ?)
		      OR (reactions_total + tips_total = ? AND livestream_id > ?)`,
		statmodels.ReactionsTotal+statmodels.TipsTotal,
		statmodels.ReactionsTotal+statmodels.TipsTotal,
		livestreamID,
	); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "fail (rank): "+err.Error())
	}

	if err := tx.Commit(); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "failed to commit: "+err.Error())
	}

	return c.JSON(http.StatusOK, LivestreamStatistics{
		Rank:           rank,
		ViewersCount:   viewersCount,
		MaxTip:         maxTip,
		TotalReactions: totalReactions,
		TotalReports:   totalReports,
	})

}
