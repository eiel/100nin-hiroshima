#!/usr/bin/env ruby
require 'ostruct'
require 'yaml'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

def title(person)
  "広島の楽しい100人中#{person.num}人目 #{person.last_name} #{person.first_name} | 第#{person.event}回 広島の楽しい100人"
end

def description(person, event)
  wdays = %W|日 月 火 水 木 金 土 日|
  date = event.date.strftime("%Y年%m月%d日")
  wday = wdays[event.date.wday]
a  a  roles = person.roles.map {|n| "[#{n}]"}.join
  orgs = person.organizations.map { |n| "・#{n['name']} #{n['url']}" }.join('\n')
  sns = ""
  sns << "Twitter https://twitter.com/#{person.twitter}" if person.twitter
  sns << "Twitter https://www.facebook.com/#{person.twitter}" if person.facebook
  <<DESCRIPTION
第#{person.event}回 広島の楽しい100人
#{date}(#{wday}) #{event.place}
#{person.num}人目 #{person.last_name}#{person.first_name}(#{person.last_kana}#{person.first_kana})さん #{roles}

【登壇者プロフィール】
#{person.description}

#{orgs}
#{sns}

【広島の楽しい100人について】
広島で活動している《楽しい》人にスポットを当て
その活動内容を聞くトークイベント！
1人15分、1度に4人まとめてお話を聞けます。
会のあと、登壇者4人と直接お話しができる懇親会があります。

facebook: https://www.facebook.com/h100parson
twitter: https://twitter.com/hiroshima100nin
doorkeeper: https://hiroshima100nin.doorkeeper.jp

【関連】
北海道の楽しい100人 http://100person.jp/
DESCRIPTION
end

def body(person,event)
  person = OpenStruct.new(person)
  event = OpenStruct.new(event)
  snippet = {
             title: title(person),
             categoryId: "22",
             tags: [],
             description: description(person, event),
            }
  {
   id: person.video_id,
   snippet: snippet
  }
end

def events(i)
  @events[i-1]
end

@events = YAML.load(open('events.yml'))
@persons = YAML.load(open('persons.yml'))

require 'pry'; binding.pry

# Initialize the client.
client = Google::APIClient.new(
  :application_name => '100nin youtube',
  :application_version => '1.0.0'
                              )

youtube = client.discovered_api('youtube','v3')

client_secrets = Google::APIClient::ClientSecrets.load

flow = Google::APIClient::InstalledAppFlow.new(
  :client_id => client_secrets.client_id,
  :client_secret => client_secrets.client_secret,
  :scope => ['https://www.googleapis.com/auth/youtube']
)
client.authorization = flow.authorize

@persons.each do |person|
  event = events(person['event'])
  client.execute(
                 api_method:  youtube.videos.update,
                 parameters: {part: 'snippet'},
                 body_object: body(person,event) )
end
