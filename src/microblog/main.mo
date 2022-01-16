import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
    public type Time = Time.Time;

    public type Message = {
        text: Text;
        time: Time;
    };

    public type Microblog = actor {
        follow: shared (Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time) -> async [Message];
        timeline: shared (Time) -> async [Message];
    };

    stable var followed : List.List<Principal> = List.nil();

    public shared func follow(id: Principal) : async () {
        // assert(Principal.toText(msg.caller) == "");
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal] {
        List.toArray(followed)
    };

    stable var messages : List.List<Message> = List.nil();

    public shared (msg) func post(text: Text) : async () {
        // assert(Principal.toText(msg.caller) == "");
        messages := List.push({ text = text; time = Time.now(); }, messages);
    };

    public shared query func posts(since: Time) : async [Message] {
        List.toArray(List.filter(messages, func (message: Message): Bool {
            message.time > since
        }))
    };

    public shared func timeline(since: Time) : async [Message] {
        var all : List.List<Message> = List.nil();
        for (id in Iter.fromList(followed)) {
            let canister : Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)) {
                all := List.push(msg, all);
            }
        };
        List.toArray(all)
    };
};