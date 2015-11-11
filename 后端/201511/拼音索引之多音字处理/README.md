#拼音索引之多音字处理


## 场景

>常常有这样的情况：产品通常会希望系统中的某些地方可以通过全拼或者简拼进行搜索，如人名，商品名
这时大家都会想到 pinyin4j这个库，而在这个过程中自然也会遇上多音字的问题，
如果每个字都是多音字，且有m个读法，那么n个字的组合最大可能有n的m次方。这样会造成计算特别花时间，
而且结果字符可能会非常长。

这里面的考虑有2点:

1. 在至少保留一种可能的情况下，可以指定最长不超过多少个字符。
1. 由于用户在输入的过程过，是由前往后，所以遍历是以深度优先，优先考虑最前面字符的可能性。
1. 在遍历有多少可能的时候，采用深度优先的好处是可以最快获得结果，而没有必要把时间花在前期大量的计算上


```java
package com.lenxeon.utils.basic;

import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;
import org.apache.commons.lang.ArrayUtils;
import org.apache.commons.lang.StringUtils;

import java.util.*;

public class Pinyin4jUtil {

    private int length = 0;

    private boolean firstLetter;

    public Pinyin4jUtil(boolean firstLetter, int length) {
        this.firstLetter = firstLetter;
        this.length = length;
    }

    public static String getFirstPinYinLetter(String chinese, int length) {
        Set<String> set = new Pinyin4jUtil(true, length).makeStringByStringSet(chinese);
        StringBuffer sb = new StringBuffer();
        for (String str : set) {
            sb.append(str).append(",");
        }
        if (StringUtils.equals(String.valueOf(sb.charAt(sb.length() - 1)), ",")) {
            sb.deleteCharAt(sb.length() - 1);
        }
        return sb.toString();
    }

    public static String getPinYinLetter(String chinese, int length) {
        Set<String> set = new Pinyin4jUtil(false, length).makeStringByStringSet(chinese);
        StringBuffer sb = new StringBuffer();
        for (String str : set) {
            sb.append(str).append(",");
        }
        if (StringUtils.equals(String.valueOf(sb.charAt(sb.length() - 1)), ",")) {
            sb.deleteCharAt(sb.length() - 1);
        }
        return sb.toString();
    }

    private Set<String> makeStringByStringSet(String chinese) {
        Set<String> result = new LinkedHashSet<>();
        if (StringUtils.isBlank(chinese)) {
            return result;
        }
        HanyuPinyinOutputFormat format = getDefaultOutputFormat();
        char[] chars = chinese.toCharArray();
        if (chars != null) {
            List<Set<String>> list = new ArrayList<>();
            for (char c : chars) {
                Set<String> cPy = new HashSet<String>();
                if (String.valueOf(c).matches("[\\u4E00-\\u9FA5]+")) {
                    try {
                        String[] array = PinyinHelper.toHanyuPinyinStringArray(c, format);
                        if (firstLetter) {
                            cPy.addAll(Arrays.asList(array));
                        } else {
                            for (String str : array) {
                                cPy.add(StringUtils.substring(str, 0, 1));
                            }
                        }
                    } catch (BadHanyuPinyinOutputFormatCombination e) {
                        e.printStackTrace();
                    }
                } else {
                    cPy.add(String.valueOf(c));
                }
                list.add(cPy);
            }
            exchange(list, result, length);
        }
        return result;
    }

    public static String upFirst(String s) {
        if (StringUtils.isBlank(s)) {
            return s;
        }
        String first = StringUtils.substring(s, 0, 1);
        return StringUtils.upperCase(first) + StringUtils.substring(s, 1);
    }

    private void exchange(List<Set<String>> list, Set<String> set, int length) {
        if (list != null && list.size() > 0) {
            Collections.reverse(list);
            String[] temp = new String[0];
            getCurrentDepthArray(list, temp, set, 0);
        }
    }

    private void getCurrentDepthArray(List<Set<String>> collection, String[] temp, Set<String> result, int depth) {
        if (depth <= collection.size() - 1 && length > 0) {
            Set<String> set = collection.get(depth);
            for (String str : set) {
                String[] item = (String[]) ArrayUtils.add(temp, 0, StringUtils.defaultString(str));
                getCurrentDepthArray(collection, item, result, depth + 1);
            }
        } else {
            StringBuffer sb = new StringBuffer();
            for (String s : temp) {
//                sb.insert(0, s);
                sb.append(s);
            }
            length = length - sb.length();
            if (length >= 0 || result.size() == 0) {
                result.add(sb.toString());
            }
        }
    }

    private static HanyuPinyinOutputFormat getDefaultOutputFormat() {
        HanyuPinyinOutputFormat format = new HanyuPinyinOutputFormat();
        format.setCaseType(HanyuPinyinCaseType.LOWERCASE);// 小写
        format.setToneType(HanyuPinyinToneType.WITHOUT_TONE);// 没有音调数字
        format.setVCharType(HanyuPinyinVCharType.WITH_U_AND_COLON);// u显示
        return format;
    }

    public static void main(String[] args) {
        String str = "李重行";
        test(str, 24);
        test(str, 6);
    }

    private static void test(String str, int length) {
        System.out.println("--------------------------分割线----------------------------------");
        System.out.println("原始值=" + str);
        System.out.println("以下是最长不超过" + length + "个字符的计算结果，如果仅一次结果就超过" + length + "个字符则只输出一个结果");
        String result = Pinyin4jUtil.getFirstPinYinLetter(str, length);
        System.out.println("全拼=" + result);
        result = Pinyin4jUtil.getPinYinLetter(str, length);
        System.out.println("简拼=" + result);
    }

}
```

##使用示例及测试

```
--------------------------分割线----------------------------------
原始值=李重行
以下是最长不超过24个字符的计算结果，如果仅一次结果就超过24个字符则只输出一个结果
全拼=lizhongheng,lichongheng
简拼=lch,lzh,lcx,lzx
--------------------------分割线----------------------------------
原始值=李重行
以下是最长不超过6个字符的计算结果，如果仅一次结果就超过6个字符则只输出一个结果
全拼=lizhongheng
简拼=lch,lzh
```
