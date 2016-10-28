use strict;
use warnings;
use Irssi;
use vars qw($VERSION %IRSSI %config);

$VERSION = '0.0.1';

%IRSSI = (
  authors => 'Robert Jones',
  contact => 'ahrotahntee@live.com',
  name => 'pushbullet',
  description => 'Push hilights and private messages over pushbullet',
  license => 'none',
  url => 'https://github.com/Ahrotahntee/irssi-pushbullet'
);

sub print_status {
  return unless Irssi::settings_get_bool('pushbullet_verbose');
  my $message = shift;
  Irssi::print('PushBullet: ' . $message);
}

sub create_push {
  my ($target, $nick, $message) = @_;
  my $apiKey = Irssi::settings_get_str('pushbullet_token');
  my $payload = LWP::UserAgent->new;
  my @headers = (
    'Content-Type' => 'application/json',
    'Access-Token' => $apiKey
  );
  if (length($target) > 0) {
    $nick = $nick . ':' . $target;
  }
  $payload->post( 'https://api.pushbullet.com/v2/pushes',
    ['type'=>'note','title'=>'IRC Mention','body'=>'<' . $nick . '> ' . $message],
    'Access-Token' => $apiKey
    );
}

sub print_text {
  my ($destination, $text, $stripped) = @_;
  my $server = $destination->{server};
  if (!($destination->{level} & MSGLEVEL_HILIGHT) || $server->{usermode_away} != 1) {
    return;
  }
  my $nickEnd = index($stripped, ">");
  my $nick = substr($stripped, 1, $nickEnd - 1);
  $stripped =~ s/^<\S+\s*>//;
  $stripped =~ s/^\s+|\s+$//g;
  create_push($destination->{target}, $nick, $stripped);
}

sub message_private {
  my ($server, $message, $nick, $address) = @_;
  if ($server->{usermode_away} != 1) {
    return;
  }
  create_push('(query)', $nick, $message);
}

Irssi::settings_add_bool($IRSSI{'name'}, 'pushbullet_verbose', '0');
Irssi::settings_add_str($IRSSI{'name'}, 'pushbullet_token', '');
Irssi::signal_add_last('message private', 'message_private');
Irssi::signal_add_last('print text', 'print_text');
