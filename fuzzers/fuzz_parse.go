package myfuzz
import (
	"github.com/antchfx/xmlquery"
	"strings"
)
func Fuzz(data []byte) int {
	_, err := xmlquery.Parse(strings.NewReader(string(data)))
	if err != nil {return 1}
	return 0
}
