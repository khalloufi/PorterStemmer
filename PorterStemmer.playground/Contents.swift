/*

   Porter stemmer in Swift.
   Issam Khalloufi
 
 */
import Foundation


class Stemmer{
    private var b:[Character]
    private var i:Int /* offset into b */
    private var j:Int
    private var k:Int
    init() {
        self.b = [Character]()
        self.i = 0
        self.k = 0
        self.j = 0
    }
    /**
     * Add a character to the word being stemmed.  When you are finished
     * adding characters, you can call stem(void) to stem the word.
     */
    func add(ch:Character){
        b.insert(ch, at: i)
        i += 1
    }
    /* cons(i) is true <=> b[i] is a consonant. */
    private func cons(_ i:Int) -> Bool{
        switch(String(b[i])){
            case "a": return false
            case "e": return false
            case "i": return false
            case "o": return false
            case "u": return false
            case "y": return (i == 0 ) ? true : !cons(i - 1)
            default:
                return true
        }
    }
    /* m() measures the number of consonant sequences between 0 and j. if c is
          a consonant sequence and v a vowel sequence, and <..> indicates arbitrary
          presence,

             <c><v>       gives 0
             <c>vc<v>     gives 1
             <c>vcvc<v>   gives 2
             <c>vcvcvc<v> gives 3
             ....
    */
    private func m() -> Int{
        var n = 0
        var i = 0
        while true{
            if i > j { return n }
            if !cons(i) {
                break
            }
            i += 1
        }
        i += 1
        while true{
            while true{
                if i > j  { return n }
                if cons(i) { break }
                i += 1
            }
            i += 1
            n += 1
            while true{
                if i > j { return n }
                if !cons(i) { break }
                i += 1
            }
            i += 1
        }
    }
    /* vowelinstem() is true <=> 0,...j contains a vowel */
    private func vowelinstem() -> Bool{
        for i in 0...j{
            if !cons(i){
                return true
            }
        }
        return false
    }
    /* doublec(j) is true <=> j,(j-1) contain a double consonant. */
    private func doublec(j:Int) -> Bool{
        if j < 1{
            return false
        }
        if b[j] != b[j - 1]{
            return false
        }
        return cons(j)
    }
    /* cvc(i) is true <=> i-2,i-1,i has the form consonant - vowel - consonant
          and also if the second c is not w,x or y. this is used when trying to
          restore an e at the end of a short word. e.g.

             cav(e), lov(e), hop(e), crim(e), but
             snow, box, tray.

     */
    private func cvc(_ i:Int) -> Bool{
        if i < 2 || !cons(i) || cons(i - 1) || !cons(i - 2){
            return false
        }
        let ch = String(b[i])
        if ch == "w" || ch == "x" || ch == "y"{
            return false
        }
        return true
    }
    private func ends(s:String) -> Bool{
        let l = s.count
        let o = k - l + 1
        if o < 0{ return false }
        let characters = Array(s)
        for i in 0..<l{
            if b[o + i] != characters[i]{
                return false
            }
        }
        j =  k - l
        return true
    }
    /* setto(s) sets (j+1),...k to the characters in the string s, readjusting
          k. */
    private func setto(s:String){
        let l = s.count
        let o = j + 1
        var i = 0
        let characters = Array(s)
        for i in 0..<l{
            b[o + i] = characters[i]
        }
        k = j + l
    }
    /* r(s) is used further down. */
    private func r(s:String){
        if m() > 0{
            setto(s: s)
        }
    }
    /* step1() gets rid of plurals and -ed or -ing. e.g.

              caresses  ->  caress
              ponies    ->  poni
              ties      ->  ti
              caress    ->  caress
              cats      ->  cat

              feed      ->  feed
              agreed    ->  agree
              disabled  ->  disable

              matting   ->  mat
              mating    ->  mate
              meeting   ->  meet
              milling   ->  mill
              messing   ->  mess

              meetings  ->  meet

     */
    private func step1() {
        if b[k] == "s"{
            if ends(s: "sses"){ k -= 2 }
            else if ends(s: "ies"){ setto(s: "i") }
            else if b[k - 1] != "s"{ k -= 1}
        }
        if ends(s: "eed"){
            if m() > 0{
                 k -= 1
            }
        }else if (ends(s: "ed") || ends(s: "ing")) && vowelinstem(){
            k = j
            if ends(s: "at"){
                setto(s: "ate")
            }else if ends(s: "bl"){
                setto(s: "ble")
            }else if ends(s: "iz"){
                setto(s: "ize")
            }else if doublec(j: k){
                k -= 1
                let ch =  String(b[k])
                if ch == "l" || ch == "s" || ch == "z"{
                    k += 1
                }
            }else if m() == 1 && cvc(k){
                setto(s: "e")
            }
        }
    }
    /* step2() turns terminal y to i when there is another vowel in the stem. */
    private func step2() {
        if ends(s: "y") && vowelinstem() {
            b[k] = "i"
        }
    }
    
    /* step3() maps double suffices to single ones. so -ization ( = -ize plus
       -ation) maps to -ize etc. note that the string before the suffix must give
       m() > 0. 
     */
    private func step3() {
        switch(String(b[k - 1])){
        case "a":
            if ends(s: "ational"){
                r(s: "ate")
                return
            }
            if ends(s: "tional"){
                r(s: "tion")
                return
            }
            break
        case "c":
            if ends(s: "enci"){
                r(s: "ence")
                return
            }
            if ends(s: "anci"){
                r(s: "ance")
                return
            }
            break
        case "e":
            if ends(s: "izer"){
                r(s: "ize")
                return
            }
            break
        case "l":
            if ends(s: "bli"){
                r(s: "ble")
                return
            }
            if ends(s: "alli"){
                r(s: "al")
                return
            }
            if ends(s: "entli"){
                r(s: "ent")
                return
            }
            if ends(s: "eli"){
                r(s: "e")
                return
            }
            if ends(s: "ousli"){
                r(s: "ous")
                return
            }
            break
        case "o":
            if ends(s: "ization"){
                r(s: "ize")
                return
            }
            if ends(s: "ation"){
                r(s: "ate")
                return
            }
            if ends(s: "ator"){
                r(s: "ate")
                return
            }
            break
        case "s":
            if ends(s: "alism"){
                r(s: "al")
                return
            }
            if ends(s: "iveness"){
                r(s: "ive")
                return
            }
            if ends(s: "fulness"){
                r(s: "ful")
                return
            }
            if ends(s: "ousness"){
                r(s: "ous")
                return
            }
            break
        case "t":
            if ends(s: "aliti"){
                r(s: "al")
                return
            }
            if ends(s: "iviti"){
                r(s: "ive")
                return
            }
            if ends(s: "biliti"){
                r(s: "ble")
                return
            }
            break
        case "g":
            if ends(s: "logi"){
                r(s: "log")
                return
            }
            break
        default:
            break
        }
    }
    /* step4() deals with -ic-, -full, -ness etc. similar strategy to step3. */
    private func step4() {
        switch(String(b[k])){
        case "e":
            if ends(s: "icate"){
                r(s: "ic")
                return
            }
            if ends(s: "ative"){
                r(s: "")
                return
            }
            if ends(s: "alize"){
                r(s: "al")
                return
            }
            break
        case "i":
            if ends(s: "iciti"){
                r(s: "ic")
                return
            }
            break
        case "l":
            if ends(s: "ical"){
                r(s: "ic")
                return
            }
            if ends(s: "ful"){
                r(s: "")
                return
            }
            break
        case "s":
            if ends(s: "ness"){
                r(s: "")
                return
            }
            break
        default:
            break
        }
    }
    /* step5() takes off -ant, -ence etc., in context <c>vcvc<v>. */
    private func step5() {
        if k == 0{
            return
        }
        switch(String(b[k - 1])){
        case "a":
            if ends(s: "al"){
                return
            }
            break
        case "c":
            if ends(s: "ance"){
                return
            }
            if ends(s: "ence"){
                return
            }
            break
        case "":
            if ends(s: "er"){
                return
            }
            break
        case "i":
            if ends(s: "ic"){
                return
            }
            break
        case "l":
            if ends(s: "able"){
                return
            }
            if ends(s: "ible"){
                return
            }
            break
        case "n":
            if ends(s: "ant"){
                return
            }
            if ends(s: "ement"){
                return
            }
            if ends(s: "ment"){
                return
            }
            /* element etc. not stripped before the m */
            if ends(s: "ent"){
                return
            }
            break
        case "o":
            if ends(s: "ion") && j >= 0 && (b[j] == "s" || b[j] == "t"){ /* j >= 0 fixes Bug 2 */
                return
            }
            if ends(s: "ou"){
                return
            }
            break
            /* takes care of -ous */
        case "s":
            if ends(s: "ism"){
                return
            }
            break
        case "t":
            if ends(s: "ate"){
                return
            }
            if ends(s: "iti"){
                return
            }
            break
        case "u":
            if ends(s: "ous"){
                return
            }
            break
        case "v":
            if ends(s: "ive"){
                return
            }
            break
        case "z":
            if ends(s: "ize"){
                return
            }
            break
        default:
            return
        }
        if m() > 1{
           k = j
        }
    }
    private func step6() {
        j = k
        if String(b[k]) == "e"{
            let a = m()
            if a > 1 || (a == 1 && !cvc(k - 1)){
                k -= 1
            }
        }
        if (String(b[k]) == "l" && doublec(j: k)) &&  m() > 1{
            k -= 1
        }
    }
    /** Stem the word placed into the Stemmer buffer through calls to add().
        * Returns true if the stemming process resulted in a word different
        * from the input.  You can retrieve the result with
        * getResultLength()/getResultBuffer() or toString().
        */
    public func stem() -> String{
        k = i - 1
        if k > 1{
            step1()
            step2()
            step3()
            step4()
            step5()
            step6()

        }
        i = 0
        return String(b[0...(k + 1)])
    }
    public func stemWord() -> String{
        return word
    }
}
let s = Stemmer()
let word = "meeting"
for c in word{
    s.add(ch: c)
}

s.stem()
