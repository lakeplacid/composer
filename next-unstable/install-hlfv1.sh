ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.3
docker tag hyperledger/composer-playground:0.17.3 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� r�nZ �<KlIv�lv��A�'3�X��R�'�����h��G-�)J��x5��"�R�����׋�6�`� �� 9g����!�CA�S�"�$�5����&EY��rV6[U��{����ӭ��>�c�ٳL�,]vl�3����_8��C�dR�7���/-I!uAH��d:+$y�2b6s�D���s\�F�k��s<�I���r�mG3�<�*^�8����<�!�넝�g��ʚ��]C��|�J��܁���¶������JQP˴]��D(��.�|��w�3��7�}ڪ���.�ۆ���Mr���ro[���Җ[���T|#�ڐ8u�Ƴ����%��tF�O	�J�:'3�;n�3��]��q�{
4�������@�_�i1)����)����E��$�ҌDKv��cz��Qt�RT��j6���� m��n�o5��G��gQt=��\AV_��Įn�*�A_8n�Ti,�nްzH3`Bt�b���ڀt�Ϣ�8`�Մ��m9~S��w�l�fߐt�D����'ؿ���Ŕȧ�Y��D^���LJ���yD�=Cq!)DnWvѾ�(*�q�<�P����ft�I���״�]�r܆��pM�*�,Ş\�6zD�wC ��d	E���m�Ҁ�+]E׀�M��Q:Q�����(l��t�����b��'��a���d�#�/B��!��ڄ�3"��@�fXj4Kv��>����Ƙi�Ƥ�Nf��{��8�0C�l�t���CcGf��5�t��Z����
TG�~Nޜa �_�� �ЇT !�����I�pa��oEC�:��.	����N�wՄǡ�A1nc3��б�`�`+.�w5��L�N�g(ʱGg�UNtQa�/u�*�̣�X�:�#�ȴ�݁�w�`+*Br������	\��t�����۷ǀS�@&��G;P� 4ׯǎ�p�i�������dM��8)�Dq*�Ϧ��y�?�r�����yy�2���syJ4N�!�L��A�)A�����f���,
˓J� ��Æ˲3G�5�EmH�fdz$�M����r��h�m�4 �1�!�������f�Q�h.}�	�����~b��W����]%,�\9vI�ThT�����fe�vs�l�5�9� ��voA��x=B����(���5��������qF���0�̒��Q~7�R��۬T��[�㹞 �Ż�F���:׏a����fc i�������=��p�T ���G���L�K?B6F��`EBs�cYͣd�22�^�Q���6�J�@���0�i�N �b6�|�4�ID��@��Zy���f�KV�aQ�sL�Th��Ա�� ��?��0���??����S0�(q��<�U��-��>���U���ߴ�u�h�1Pz�0+�q�ux.v\dy6�@�	[�v ��7��0��1�k$�@�S�l�.P t`�{�Uy�Nj��k9�DZ�^+�����CJ�4u'N�C�g���]Ӧ`�����5��%@�M��8Ϛ��oڪm�K!�#.[���+]Y3F5��{t��0�b�=�x�-O�՘l+]� ;t��n�X���5�8��� ;
�]�6Tl(�$����\\qCjc�C�5	�?�Q̯ߒ�j���B�s�����*�������p��Ϣ�����2��ߴN����?��&���,ʹ���e��+6��{c[R{�Q�l�����?����/�!�����6�����r�����I����N�1����??�;�r��OoU����z��G3Չ��ز�m*j�f�q!��ocx�ov,B�N�����0}/�;˓������/'�?=�^GN�����0#��O��p>�gP^x�_㭀�?)
=�Oe�l���b�|�6e��o�Újk��"lۦ}Y�f����^O6T'Α#��-G��k��Sn���FG�%��S���T���ѹ��#���U���"��o��ǴY�<��`d�:܂l��l�4	�L�^�=K���(;�~�q���]��x������Z�G���xr<������)���sss�X��u�8�Z��Q�-�/�c,Z��I_�##C �u���K����z�<�on��ۜ�s�Z����Σ̢�;\pox� �mKK(JЅ�#Dg��ϗ�K.���%��٘��ե�=��z���{�S�?���zq���]��+/��C��:�n+H����_�x�޴'���MB�X���2F
l�s����Y�D�}Y;���p�4���f��>H'�9�C�lv{�n��Ͻ
�.ۄ������1�B���*ϐلp0�&��A��caϊr�q��4�gj֕����,X�q��q�,�������@1<,Q`��g�4�bJ�2��L���i���:�`|l�C��a���Ǳ�">1
�����FԠ��Q\�-WV6����&z�����i�"�3M� D_H0{��Xkz�qz(���_�a�]c��&��D����3�4����hy���5n����g��T��L���Ϥ�n�7�6�Ķ��⯞$̣�Cȕ;=�r�_J"�G�KA�ϵH�K��8�<�1!.����[]��^��
}l�|7?~�=�S�j����S���߾��y����˯������,����(���B���
|&���?��H�#������L
�ئ5��N�E�B���8���4H�����扳�(=��c�c\����%���G��b�7ʅ�G�?@������nc[�bz�L�۴��z��`�CsOu�d�P�XX!��� K�!��-�Q��+{��yM��=�q�#b�A��u��W��-�bB~}~b���O���Rb��q& ��lh�2�\�hb�������NԼ�T��c��(O�P��.�UH~�t0ɲtM��f�&����FߔRob�&x~��@Ǜ]��{[\�mT���(��(�H���j���f�k�N���ۘvR����f���7���P�)1S9�S�Th�&���sȎa͡ ��8B9]��Ud�Z�&��5���Ө���W�sG>��;���� [&P�m�	����&1�|�	�K8O�/s�J����c�3۴�E]r}b}��f�y����B̅�UJ�u���J�8�= �� F�4�pO�"�i���=�]h���N@dBwd9Z�c@	3�|���-�0C�g �61���!���P�Ȗ�,W͒�<j���Z��n<�����6�Ŀ��Dv��Y�-x����ݣ=���r�@��5mr�?�a��M����g�Z��W?pa�c"�)�鐯VtP4�.[=����>j��o��Y��m����Q��Ox�EbD��F���xhbx�N`��U�q��l�M��my���o0┋��z-�'�*)�1���Y�-A~l82�f�٤���e� ����8�z3цeJ�#B�(�jԄ%sF�523�J��w\�v�����Ӄ'���H)ɛ;f��JD������>	F��0ڒ���qp�b��O��-�.�~S�a�s�r��H�����{����3�c6�E�R<K�Dt&�oj���Y�_6�� �����;0��l�8@NqLDy���/���=y����,���v�v�:7y�c�	|��Ԣ/QaJ�0tA�LV���t[��p�}rɴ�.��zlk��R�,���]�O(��s��Zs�A�/0M�g���F��?�q!p27>���}�$kcu�hB�&�L�ͺ��v,�� �5_"k�N�!���'��5��5�A-�@�F 7d���pXN�z��`T��ӳ.�t's��)7-��8}�1��s��S���(5��|��'`NS���Fb"9��i�O��@�>����~c2S>u�8Bq�lB�
�g�+Dte֊�MMvx�/8�g���*�G?O�q���|:+N���3�����Y���v�Ǘ޻�����_����_�:�q'[��J��Ŷ"(B*'�[픲��eڭ���2N	8�I�Z�dJ�S�t.'���i���NG��=�'�qӈ#R�7�Bv�"��_"k�ȅ�7��|�u.rt���__����$�/.^�8��r��Չ�^�W.}+��.�=�w����?��_���"���sƯ���_���=󬼆��>��x���SI~��3������^Fɕ�3?��ܟ��_7�����ݟw����������|������})p�'pC�ѥ�߽��g�W|@�]��M�q'�I.&U,�r*�f3Y,��d*�R�Bg���#�Rrb�UA�my1'�Ix W��ޭ�?����'����/~��_��_����X�?����#��1�Ahc:�G~��,���G�?��w��������Vus#��F��0�/r��M"��~��By�RC�r�YY��f��r�J�X�+%��H�JA�Tꥻ������MW��[�igo�_(Ik�N�Iwo}�^/I{��j��s��Ni�^_)��no��U $	[�b��V�������v����B���ږ��U�����������:,?�ֹ[���w��fZ�+ˮ�2���j�fY�L
#����q�%����CI����{�tu�uCVW��juP<��:�킴Ӕ��f�Q���*�Uڹ?��r�VO�V;�e�����B���4���V�f)b�����/�)�ZyP��+�{����}��Z��vĜ[m��+
S�ʃ���fz6��~���Y]3V���Tߩ��%��������E!�S(-��;7+�kw���z�I7q/���~�Ɏ�	�n�[�*Y��cWZ^�[��X���⺇�˵�M�I� �4�2 ��ʵvu���~C��&
�}g�W��,�wA>Uig�+,�?�~�O��x�/�˅ġd��S�J��Y�]�I�)wVE��5�'���n��5S��z�9��c췻֓T��	�[-5 eC�t�C{/�o����ܩ�� ���oj��2�͎�*:�R�9\��u���������7�܆�b,JV+�\���Z���2WoW���GM�\+5�蟜hM+Ě��ȚR�[7�k7�j��24d5���ק��W������,�[-noW�C��Բ�,�׺������˃�=i��)��6�i�N�-���;��`�)=�?���Gq,=�F�Q�;;;bv5��h3)
����+��06�`l0p���m�7�`�jr��HQns��\�_D��'	�*(������=]�i��2v�9��}�s����� һ�^X��á�eþN�l�Vyƺ>G1TB��'�ա�*��#	U	nj&�FW���1��v��%��g��),|����<|e#�$���=ۇV��R��f|A丛ǱPe`�a�u��e5DouC���J���9""�Bfː��>6;Ԥ��zV��U���B���"�˪NI�2h��>.�D?����+.BI���/~�%m[�yF�� -�e����F�«$��X�j��NW}kM�KC�V}צ��Tw�j4V0W!� ��*nYk���n��t��"�9I�𰦑'�K��x��ӄI���~��%��gf;��nP�%_'j�|�ʻ��2� �
M�u��Q�MvNS���n1|�c�_C_�U-|��O���<�Qt>	;�S�6]i��h���ڇ'-n��;h&a���Ú��CI�y��%�j�١Jb��BO9�^ Jb����v�y�:Ɵ���7��n���ƶ,Z/���omg��l*Ҝ6��x`�U�2,!80%��-�ߊ'��]!�|�-�����t�?�~����C��mA��4��ՆŌ�1�P�������~�Lu��Z�t�)N�D��6Wf=ӧ��Er!Ɯ�t���'ju���بu��o7VN�oyc�㦛29�e'�V:��-���~WxU�����W���E��n������=���o|�'��'�77�V�|ks~p�����:x�W�������y������_z�?����W���E�����
��]�n��������ng������q#����¿~[��oO�'��Q*��T6�nc��7#�&k�T�juɁ�\�|���1��3�1�s��~�ĕkbᅘH��sA�Q��!x�z�j>g.蚺�X�o�+��2pWa�Gn$�{�P�D��c��s,$�6p(,��hX�U��#�*�&9R.�[iM6qsS�SDmLa��U��n����!nj�N��h�Ǚ����"����;s�C]�i\�L�*�_�e�wd�ɡ9c��	�c�g��z�5��L�%���.x_X��la?X��L��\�HQ�%Η���^E�MF��L�I���*ó0A�ݍ�]�F�a{:� ��v)|�m�vI��v�@�+vc��C���Ґ��C|���YݔF2^r$e��V;���?�ӣ��K��}�ZO.IR{�)�z](���������[a�c���ȕ=�9
d~���:�*��)|o����ʏw�d~8&]�O���H��;���~��Е�1���w���mN֚���[Ƚ��G�(�J3��֤Yo�=14�j��k����RqlZ{��ʘ�!�Uw�~ܚ�i�`����df��K}�!��RU!�'������BY�ʜ�0q����XN��9�ӭB�}��K~����o]���v�t��C(�^J�e�"T�?�Ҥ!�X��-7]��q�96ڃ� ��F�X̓⩵�+Bu�j���^��7檁$P���vq$���0������N��������m Q��T[̺�V����\�����$�Xdnɶrԏ�C0�_�C0�`�����u�c�`�J��1�@����3Lkw��(��Do
P��M̩@�/.d<-o��.���/Ě0��SK�������P�&��z@��p�D���Q�	(T��3�X�Ֆ�}l�H+�Ś/oJU�(�\t��+hl�Jոü��¢�z��Y��eB��k�tL�o0�.�m2�)�OP�E�z��0٠]��X���5�c�%�����B��';��wLZo��Pg:�R�V��C����L�~]��\��.BO����`�����4�_C��hіF��j�8,�:���o�_&���,\����7�/�/�E4�S~������/^A�����o����9���:_�R����9z;��Я�d
�cM������=q6��Y����w�7U+L�,b&������D�C7�y��?@���ފ���h��J�N>�W�w��N�K�77�sZ�T 
��߾m�[�H&��+�� �g���dI�S^��_��?$����4���Z�;����!0�?�������?{N�c(
�?�)�)��>���`��"����������F��~�A���������_���C�=�����_�*��6ނ4���O%�� �����S�]�'a�H���kU�х ��?���������SAf���1��� ��Ϝ�Q��G ���L�߱w�A�� x& ��Ϝ�1��d�\�c�/6�Cr����I���������N����K m�m���wI�Ⱥ�~X�B�!������K��0�g` S ����_.��g��M9����� @:ȅ�����H��� �@�/:=��1r�����@���L�_4	��l���������(��4���zV��\����?$��* ն@�-Pm�9ն������g�L����?K ����_.���̐� �A.�?���`��������\�?��/#d����.��+��� ����y��X�����|�C���v��C�(El�F]�񬁇�	ץ�.���y6m�!p��A�$���c}w?u��1������tp���-�s�E�ׄ����U���6fE8���M�Ir?uɽ����3�����E45��-�ڢ�G��p��LW��k�(��{�"Zd��rX��ֶ�#�1�r�@��M�lY2�O[1��_"��b�ug���˜��j���Bn���Me���y����gv�,�G0��!��������GvȔ��_���f�1�X�������������j�f���PLՊ1��+3V}�kp�:���~O?����7j�Omg5o���t�t�)���Ё7��f��+��R��SZּ�@��
1�E�x�����cq��\h�-���"����oF�4�;�g�)~�?�b���� ����/������j�h���G������K������[��P�hUY���jy�N 
�N������>���}�<[a�"��������A�m,1�2o��DC�G�����M����[��,�5�]/6�K*���/��A�ͅ�Y���T&�`�Y����am�jBmd��Ra�kuv��?i�
4�������u3�+�*���Wi
q�e�v5iw��҂�u�D�
��Xd�	�'j�s��i>��*L 0�߫�r5CMt*�ƣQ�hЫ���N�׷�`�+GI����9���Rn�F����$�#�V�������k�s�A�!�=�?��K=��}^s�4����?���X��r���=�꿤�T�y�- ��Ϛ�Q���_a��i U�^s����]��� ��
�����_3���E�W��_JHE��}^r��_������E�W��?%���`��|!������ ���������迏���>/���/[������i�?��%_ȅ��g���T �����_^.�����>z��98�|"�����@��T���.��B���T���<8��1!s ���5���=�$��4�-���Y�?������e���d�d	����3��b�_��/%��AZHH��ߵ��J���� �?�����{���
��a��ܐ� ��������e�<��=g�a���\��{�?P��c*x���|��q����4��0b�`&�;��J��I���������<��q���3��i*�@7��r@ʛpY�7�ޜ�,tX+K��Hj.��֢�+��S��Ȧ0�K�m�e��ٽ�5T�ΰ�:�m#�ƒӝ-����(Iy�(Iy(�3q����ڤ8���!���`��L�K���a%�73uӶ�I,�SU��r5r��`6��9�a��M�E��"���ً���\�?��@�G*�^���Y�����r������`����+��!SG.��=�1��S���?�����#��@�e��@q�,��������3C���L���`�?3�����#���r����@�e�����݅�|�������/��!��a����4N9Fyi9]��ۨG�6���z(
�i�@�(��ǵ)ҥ�: �?���	#���������3��lI��-��&��_�2��(�"����+8}�]丛ǱPeE8���M��O�>+��^A����D��Q����~�!{�ۋ���$��Ʈ��w�Rm����V��.����O&�8&�x��1�R7��L��Z��M9
�����R?�
��bȹ,��H���~�⦲��s�<�P�3;d��	���y����e�\�?�������}s��Y/y����Ç�s=1����e�4�!�4�-sĪ3]�G�z���<�?R�vĲm,��b���z�OJ\��k&-��.t�.�u(����N���X}��ݨ!�>��V�9����4��^w;�Q����|����/E���������Y}����X��2���_ ������2�0�A��_FxL�����[�W:Ҝm�^	-�#3j/��Ų����!���j B�D��<�����D ��eiE.�EًCU�M֖팇�C��A>�и�9�~��v$�wW�p�5�"����U�9�P��H�_T�v2�����2Jtk1qU��y�սJ��ǲZ���ɘ`(2���wn͉�[��X5r>\���*�(w�=��������ӓ���L��g���I:�������ۖJS~9/{�4�2y��73���޻a�Wt9l��^�S�b,��zhIx�u�lK��O����/��w�ь�k =ѵ���/b/H$��Be�vGK����H����9�!]�����:i^�Y���b��D΢��}w�	�#�3���;�m����.`�t�����Y���_�!�'����E��0ӫ����w��b	
���/����`����ﳞ�L�Ft��<O�Tʓ���7b��b�$IÐ	��x�����<��I0�W^������P��"~e�_[cW�H�6h����e�,�Ɖ���*{�"N�i�o��?l�E-�G���{+ux����������O3ݡɫ������s4���P�'�W��,N��� ��s�m�A!��MBJEDp}�f#!�i'�4�8�Ҁ�B6b"<	"H����~u��G�_�?$�J��b�T���A���e�c��&���懤s
�>��19����{]��c�2��r�[�2���R��?NB�WE z��f��������/���?
����������S��$/����x����?�����2�/M^���Rp�QP�G0���"���Cq��U���CP���?���G$�A�I���'���d����:8*���z�0����P���6�T�|e@�A�+���Uu��(������������W��̫��?"��Q��ˏC��'�J��v�#�j�#ÐP������,&����A���<�6�ˎ�%L1wK���2g.]�AQb�XJU��Ƚ(�y�F�'Y2��.�?F+f3qϔ�Z��i�d��+��x�<[�����?yjB��6���"�Ȕ��"*�V@�=���u`���߇�|��q̽lQ��ou`'���G�W3 ��)��Z����hV$��;�Z�bQ4��9K����6��B�}�l'�� .{k���ͲX&{���<[k,Blzi���ؖ�D�]�z!3��l�e+{����J�$�V���L�*��\�S���Ծ�F|.s���xy7��2ZѳA���+�L#�����v�����4{���ܝ��t��_V��뗴E=�ϻys����$P2s��~�\����ن��8jM.F��ɺ:^F.�Go��mQ]��q�N�_�}�8
6HM~T��[AX-�G����	u���Y��@5�����_-��a_�?�FB����E��<���i�}����	?�����G?�����j�㦤��17˕�r��+����/����_�*���_��$~�Zbp��tҚb���KmY���\'MG�{�Nz���O��ϯa�\
o����2��\���Ԕ�{��,����#>�TH>�w��"���z���4 ��i蘣�{��lbxsf϶��g;I[wވ[�n:	�h�p6cL���M��!�fܷY�V�jVsǑ��H��S��}����jYK4��*�EѼ��^����)�.�v~p�$]���]��j�Y�Hz�.�YsFv���)�����2<Mŕ��Lƀ�d%ۆ�$���"0�М���ҙd���r$帙�ِ1�|eu�q�ΕM��)p�!6�Z?�gg��cl�����v��Z�/� �������p H T�����B���_�������}N$ �Q�ϐ��a�~����������r;�-H��Z��/my}~}�OVr����>��m�
v+�'5 ��0m�� ��B��� �O��L�y�ͻ� ��B��4�����U�s�N�m��E�g��9n4?/�m=<�\�aL�9-��<���n@�v����xG���̃��?����S����6dQ�� \�:^�=�X�Z/痒��XgKj:ؾ�>���+jGZ��AilB�h&c�^!�����x�0;3Ծ��B��q�����-�DQ{�hƺ���E},��V�.�T^yv��.ɃZ���+��_p���J ����Z�?��ʨ��C b������:�������_m��������$�(�C��H��>�%�����k�u��|0��?j��q�C<��0�#��p>�$�萏���`X>����( x.B�!�i��-q���`��D���o8��ݮd䳦0[�,���>$Ɖ�z��q�n%��6k��m���;������..�@�����y#L2�-���f�L{�0�H#�Y&O�����G&d�͖{8w[��'�D2��)����R��?��������%�VI��������?*����\m`���ף���:~���G�ɜ��S�kc���4��y?����3�D��?�e|�N��åuiҽ�C�vS=�-�A:��u�z���S[�6��A
w�z�N6'U���f�ߣ�M3)q����zޟ*������OA��"�����?�������C��U�A��A�� ��8�1`�"��ɇ���>����������O��#J�������K������W����ڵ$_�Ub.ǁ�[f�S���[l���h���df�F�X�
��L׊8��ƑP����vA{FdgƜ����^ئTaY�Y7c7�{N`�������˾�ӷ�O�N���ܶT�����Nʔ�t�Ӊs��~�,�#QkfY?���Hj�<q��:�tYe:�cָG{�E�F�Y Me �w
ݭ�2�g��㐚����:uO~:<���]��8�t{S�Z��N��b�oĂH��F3�䰥�t�a���?�o�@�� ����+^k�����?�A��H���������H�a�kM���Z�I������]k*���W��"����W��
�_�����?����?X�RS������O�$��Uz��/u���A�?��H�����������'��⥦�����_��u��X�R'�����a�`����/�j���C�G���a�+<�� <mAq�?���!!��A�I���?�h���
*�o�?�_� ��P���P�_i�Ǽ:�����@�B�L�!N�81A&t�B,K	��,�PA��AIƼ��\Bl��b�Ϣ����
�?��+�?���������Cb�,$G#Q>����Z�}a-��L�m���n��M����ᅞ��ZW}����c������z�٪܍{8�L��w����K�WR�>h��B������]�Vm���V���'=�	x�� ��?5|�@=Aq�?���9�����O����/��?���T����?0�	������������d�_���	��)���U<h�Ôb�$"��(ay�O��b8*�h>	�8!h2���S���������2�_���l�����<h[�1r�mS3�=�g�C��O������v�n��-��JX��T�&Gf�R	��/}̲�}���ٜ���M��29E��;��.ٻ�R�G.$�q0[��Msق��[�����Ձ@�o�@�MAq�?��� ���:�?�?��Ӡ�(@��������X�������A��� �j������_����?H����f�� ���\��W��D�I��>=�����a�#`����0��Z��`�#�@B�b��n�� ����Z�?þ�����z��� 	�y���?�����G$�t��s�����Ήt��d/�,i��Ϻ����v������[[g�{��)�{����������$$Oz�L�Ԗ�f�����҇0m���T����P�8�Q�]]ҳ��/B�_o5�M��Dڅ<�k��,S)��=�W���X>�{�B6E�4��~.ɃR�ſ�x��ǿ���_��SѠg�v!1�x�8�,Xr���d=�.�	��,J������P��=�D���,4iI��;&�¨��ت�uA>������ʚ��n�"�{�`�:����������k����A��?"�f�S�S��h�͂�G���O0�	�?����������U�_��_;����������x����#�����������H~���hz��8�MI=�cn�+���+����Lqq��SS�̓r����yaMCu����C�)��\t���������bѪ}���˄�O�#��䎢
g����t���2��OZK�ט�BZS��zxa�M#�t�Қ���x��I�����5��5̛K�-���T����!��g��,��g��g)$���"���z���4 ��i蘣�{��lbxsf϶��g;I[wވ[�n:	�h�p6cL���M��!�fܷY�V�jVsǑ��H���÷�g��{�e-�|��)�)��sQ4������`aʆ�K��8I�lgw���nV�$҃^o��m֜�F���`����z�d�DSqe} Ӆ1`1Yɶ�3Ih>��'4�k���t&�=�	G9nfz6d6_Y�s��se(zi
�a��G����Y��[�-����Z�ă�O����:���\��]�=���v�W������#�V��!�E)C��1�3!�38#a�'tȇ\�QD�T�rI�NEl�P�	;�M������H�����K�7槙������bE^���E8mV�Р��6o��m��������c�I��Ƒ�����I&�}��v�貭ؖI��~��$���d��}� �"uXr�#�=��B�PU(U2����u�6t?���j�g���MUƇ��Ós���M���b�Ñ���l�P؃�V������)3��81��h�ԩz����iz��6��ӥ���}{����9�����ӥg����?�,=�/��2�񟗞��߮��.�����x_�ǵ7���AaЉ���~�4�˟]�X5Ÿ<?�Trf������d��ڇʠ��
�1����ƍw�4�51��'M�TnγɫA�=�3�k�z���f�O�G}�M��q4�Ol���}��<�&����v��iz�f���D�9��
�+��G��H�����������k�������m������lm�'H��������Oak�=FZg���o����o��a�D�;�T8���jZ�������I��-�����mG����@�g��@$h�.� SU9��+����j� �� ��_��l�츔xs☙㯦��J^�[�H��A�|�nR?90.;�j���UI�4�N
ǟJ5�M!�xG{U�r3�;���u��p����\�D���w�����> ��ʓ�2���vP�3R���a������`�b����jo7�ձޱ��QdP��m|jf:M��=;�O+�����i�M��(����C��DʟD�EO�tZ{_��>'�-w|��U�w_��ϟ��ʚ��_��3����Cvl_6OJZ���%X�lv��L��;#��(���r�qw2�)7R��ӫ��/���4���?>�#}]k���M��:�-l����^��9�Z�`�z�ެq��t��1�&m��B�G^D^�N��)v�)̰Y��2������4�ʐ���$������ Z�i��▆%1Re}���� f��A����A�1�l^���쟌R �b����� v�4�-R5GT3�$`�����6B�v�L��a����h���	�AM�3�6��`X�J�?"a�L�18q$��|F���1��� ,�a�P�;H=(�r�3Ν_u<4�>�3��b%�P���� �I�A{:�lr:�5Es@D�,4���f���Z���]��U��S(C\��6�h��'�21�t��:쭐FA���&�5�,:�1�r,�� �s�,o�m��E��I`��U)o/�$��Wm���,��&�!�~|��"o�MA0��*�x Nhf�7^5�ʠ�k�NP��#��2��	6���U�0��n��+O���՝�bt�0�b�bw��oq��qx�|{��d��͞e�}��5�]�`�2G�FK]	DH���X�#�]3}0�h����&�i#1(��D!ga�(�Jpġl���s��P�\�o*֣60���jd�!�e��ԣ֊���\<	|8���9��D�E)�@R(#�bR�8C
$�W�b��
$���Gu}*rƣ���D7�+��]1���Ԩ��D�S1]É�<��l�0�Mgr�X�� `�gB�Wz��D���R3TvC^u���'�鋾����jr,Wq|�W����D�a�d��%J*C$�a:d�:.����6H�
�����Lg(�I�nsH�:��2 l�;��{3��X�F�]
4T�݉����+��k6�} ��t�V$)�
ҍd/���1�n-�ps{�u��[(!�����繇�%I�n�Cqn%TQ�M.`6���%��G�y �xw�h�"����T����X3>�{`��?�)dq���dr�<�H������GI8���E�2�2A��=�%q�ki#: �N��ҙ: ��,���N�]9m��'cT)�k�24kg���R�]�\TJG���~�9Jb)PəK*vj��6>5J b	�^klZN`�-$s�"��-nP�EbIL!/�[S�+�Tb����_��wDrW@k�M�2�G{���z��n��R5�fY%I�(��|v����]��=�Wi&�Vw�X��R4Oم}Eb=�o����ԗ�צ�X�\����(4Qܴ7r4i�u!��C)��L9_I�5�+k܇���j��wXk�ڥ�����I�C�d_e=w��X�ӭ5J�j����'��������9�u���}�uE�'K�I۹�5yl�Xc��*��NUJ'��V��/���em�j���:{K2�321�+0�.T�*��9vsL�a¶�� ���9jq�¢k����=�Ҟ\�ނ���#W�XXL0 
A)���nD,�:O!h}���r�_^v�c��p}�ٮ!���������J�:_�Z+���~8��5��f���w���H$p����V�rir�� ���0�����nQ�IR�U��c�z��t+��A��Q�~l��O�w��4]��p�!	���3+�z��=ZDؗ��(Ԫ�P��-uk�o��-�K��>�ʰZ��|�yV9��e��G ���bno7�S�����'Ủ)C�c���܇�[!ȩ��Ks����dV	��U�0���>�	�0۝��l�o�-W7����13T��A����Q�&y���.��rY�n5��(��s�x rƕKT�|q�>�&ș����8мRb�p�v�X?���3H�_�͉c�\MW���F7�֬���Tv��7[�l�%	M� Ak��M���+��%g�v���/�����X�x:��Ɩ�5�8�x<F'���3v�2ڞ�і�wB��a0�U��e2�{��L`X�=׫��,s�#����������v�'�����es٭�?F�������v�g��������l���?�����6�vSg�������i���è��������X�����_�t2�M� ?��fs���c�K�4#ѣ����n�J�A��e;�Y�i�%cK3Bu���v<�w�b�T���$�5|r-Aa����/&�F�B�����N�kYx��(mZ�xm���+����/�ft��dG��Y�R�3��m����_%�
O�3t�%�]�v�LU�9ws��AK�ѻ�2"w��H�3��� D��F<,62��]5��prsX�+<�O�'����<dKB��=o�n�4��*������ľ�F@�M�Sہ��fô:!�Ψ���X�m���cZ'��\~N����߶�������Q���:�nN=	}J�H4���?��@�y������|w�F��
X�*�5�_H�f��ry���f��?F
��R��%�̆���k�-�S�&�F����W0�x��������Wt���װ�^FD��T2-�q3���?��_W�T27��b��}=������i�wF�́7x��F�)�PM�C���ơ3��L�bjb���*H�T�6iQ�f%k��R���q'�O���I��~l"���P�,;)�^~�0}�9���ꍃ��7�9��&� m�Mb���J�K�P�;�z�����zU��fB8�h�Ѭ�����\�̦
�'!	����l�&;��D�>t4��P���$�У�Oqe�sZ���=�|�<����!S�Ĕ!XI���G`�;}#�<@!\'�ve�4���#�5a����9� ��������o ��N��T�5�r+��9�v�X�I�(����b/+�@�����|�U������Mh��dM�)�mn��F������!5v^-�Kp�D��`�cH�Y�f�J�u� ��y��,K�A↌�@��'����T�u��b3�_ڦ���E��E�Z��ȼ�9��lo��j#f�|�$����I��W�V��o>��A�N��{������ǿ9~��$���,�¿2C5A԰D�.v��M����+�P�v�bT�3-�s	?�z��v��sG������˟+Y�%��_a�9i��T_��ò�u0���%猅��챦z�s�iEW຤�+p���x4��5�+Vr��ii��V�_rJ7|%��
I��0-�õp��k�	�4`~���;��-���ac��Q�r��xfn+�d�%T^��� 4���T���>�'L�[�X��/�k�����o�z��}�,��R�K�B��O*��Lr�����J����e��I��*M*�lR�����
���l6W���"w�Q����f�d>3z<c
���-5z*�v�y�m�u��h������*���lv�^Z�ϙ�A�F�0YIl�z�$1�������4�cW��̳��-"�d����3C���FG^K�R2�W���]���U�CM,B�̖�biˎ���*�;3��G��V[�t�
���ǘ!�e�[���m6����`��K)�/�$[��Ιd��F:�n���׺۴����EK,�7�Z�������?%�����c�����MzM5�G&�0%K֔��Swr�V����~�m��'�����|n��_��6~Y�a��@�����G�ʿ����?J����q ��~­;�G�?�����P !�l	��Br�1����h�ЇY�S�&X�xǑ#�����[�ٶ��~|o:�R�{ѭ��`���N-lI"�CL�;ߖ����:c�_;�K#�Kz��k�)+�}����4�^���\H�m�!�7��<��Adߙ�:Y�P<Љx�x��L�V����F��Dtc����k؏,����ݤ��Lk�����,p��L&���{�����t�5�#^�j���E���@x���xo��/�c���"|2�]W>��Ii����0I�붢��㿩��S�w�؆�@�S�����t���&�"�t��g*�����҅t*����/��l�?%=L�oH��''�>!r�Q��HU���ZB�n�K?6���YD!C(�V!d�[��ɘZ09�����"����Աٟ�/�#�(����Ϝ]d~1t����E�w��*��P���V�.�t�jCA�k�CsGsU||��"�5-���@�sN��%H���+�1v,om	i_��<��C1uG���x�<�F�Ee d����
�N4.�x�,#cLQ��b��� ֙�+s�P���sd�t��J���5,ǈ�o�����CAH�!��tu���{"����q�W]A���x:�9�E��uZ��pk�ȯKD���D1��9oQ�7؇ <y�Q�xP�k��c<���	��G���UT]�R�P����t���� �{W����\5	t��]�7�m������"��߬�|�r\���Q\Ks�~�boo�W�4o�rE��T/��	Ok��Z;2�A�Y'��H�V����pؘ�ks��B�24-<O�Ӱ/��B���F������~� �2?��@�2mG��A�e�kH��#:���<z:�iȈ�3X�� \���O�e&_C�p�'MD��C{�Zx���>܌S�t����g@��52�<�!�įES)��cæ��iq`a�qM+��b:�l=3�f�������_N2�ta%-�8{b$z�RJ�__�y+��G�xqT�ڦnF��D�����!�-`�vIU-f�a'�U���e� ���_:�(�\�@6�ɷ�{�ozQ�q
���u9�����;�W�v��X�n�_��	�C��Y`@��0B3
�!��n0f���h#w�� ;f���wm1�ciy�w�����L���Ҕv4��؎/�Ʒ$Nb'N��h�r�q�87'N2�< �]-���j��+�+,��@�yA<��V����*u���$L�o����������������1���'z?7m���*9��]�����v�Yf�xy�V�gۭ���������	�>��S��۪w�c�Cܲ	��e�T��l�.;׾�����[x��{@��,��G�_��qE��e��H�ދ�M��띸ȉn/N;~�=~ 8�>H-�Hʟ'�o���m���7vy�>��80���lL��f��ƅ��¿��C dߟ;M�sR7Y�u
���dAާ`
=F���<K�h�Ů��h�-	�Y_���s����:��f߇~����`�ea�'5���h`�ǶC�qn�6-��<�"|V��y�W�m��\c���6.������!HA"�����A�������[��n�9����'_<z��_���H�aJE5��`�֨6�Z���F�B1��t�1��T�i�SR%�8Z��8���wo���h�+्y� ���2��_�x�zz@gW����['/��������;s�d��r��������7�Η��q��Л�]�җ��ur�V?QgY����������_������a�q��?�O���+�D�?�S������?��ை��a��r���ק?��O뫏��=|��� `
~��ֽ[V�x�/�^�y�����F�kX�N��`p#��B�N�U;p�F���G���-J������!��;����:_���O���O�d�f>���{�����0��0�o��6���~���M0�?_����~������ �п݇>���}��	�ww�9t.H�-�X��;�4�2��f�Ѩr�$���aKu�N1��o�[��,st���i��u�Fo��y�+"S[�����EW�&2�Uni���#p~EZ���D�Ѩ�*OĖ�����Me��	q����"�vY���"�D�_ܚ��=�\��*jZ�XM1Wvc��X�wŻ����f�#�j�4sm7��+��	��m���rq�quTF)G̹nܘ�� ?�Z�<~~�X���rb�����u2r��k�l�<h�(B�.�nC�,��2�z����C��;��/��)d�HMA�z���:�I��\"Ԯ��,��y���xN%��xS�b>'=v�#��UzlA��q���?h�s畕Eeե]�	���<E���!qͱ��7�Ï���;����f#ƲP�N�e��h������\λd�v:h�-��0e�7DL����BfZ%!����z�+�R��
�USqB󪓣�v������8�AJ��
�-��RZ�ᥳ)�Ϧ{�T^e����L|�-�f�o[���N��s��J*ϣR�$��_n�P�paBy�-z���q��y�T��	��hj��H�=�+b���R�,��-�!�&(�$����b��rj����TL��M�
Y�\Tʓ�P�gsD�q�M��I�4����ߕ��M�r�3�AE���P`�K��T�������e2����&��i����Z�UV�Yl��	��F���u,��(�H��v%Dr������1[���SD�#%��n���4^pE��A� &�lNY�"�uI���zg^/�4
���ǉ�?\:Q�O;�5��㒂�(�5CI��V���gi�	����X�Of�瞛P��D���|��D݄� 𹇟T�j�z�V�Sj6fYbdù8�E&�U)�d������Ǆ.UL��z��Q����>�͢@`1U�*9תS�� A�=��5p���~����~�J�n�X��`P*/�g�:��DF�[3��u�p#M��>�~�tb�Q��E�H����scv�hP��8�(��Y�.�Iz�YR���|<�*��ZQ3�Z���5ڍ�G��,[l�����=��M� ����}���K������'�����XٍW;cm!~^_nt�����l׳`��/C/{�����o����KOBxy��8���}CЁח�۞9}�Ӡ?z�����Λп�6��C?}�������C߻����q���.���̃��v���g���d��T��\��7jg8_S�6��8:��|==�knl,�����#���,z�B.p�y���d�7���:��$2�
�3>�nj(�WQ�
�0FmIsL"øK�r�t�	��!�9"X"�zY=֒Ed��8U�:����B���8[1S�A���^��3�`�0�(�J�X�0�^��E�.()tf�2�9��iY+����e�2��NstvS`��DXd��B�3d�a���:&C��V�[���Ż}�&S��w�EZ(�gt
� JCJ���&m��i;[�W��v:V���KO�0`������ր��b5c���5�p���&f���N�V��ʇS�l�/��~��I���ru�(��dXԎ,��i>���Q37;��������+�O�V�c3��R����\�#X�*+q
��Tj�S�kO%��	�2n]�Z|z5��u��j����ߢ���y�_�]-Z#9~5
�&�,�����,Ʋ��Ьl:���Ce$*�l�y]J�C��)�=�8��90���T�\�B!�q՗�,mGM��W$�ȗ��$��s(\�E�](��BQfE�vS���bX���Q�LD�k�YL0b��ذ�Yl�S�M'��2j_(l<)���w��,4iQ�j�hV�W
z2Ql+j��'��8	�HCp;Z�"�I.�x��,O�m6a
<I7j��u�<�D�I�Q���n49�?x"��//������HDiܑ{v�$G"B1�zS��g���m�H�n�^�$��-p�%1���\w	fE&�X��L4�[�I�W�W�6m��	%��#�Z���^hHX�,�x�*vxj���v�g�t��F�9/(?)=D�h*_��8���T�[h�#�,:� :k|F�.����C(��.+�H������t$7�]�H��	�ttR���abB9��kBa�f��G����\���^(��.��I�w f���t�!��dL5�1n~R�GZ��1q�\��fM�J�V�����M��^9�K���n襯@/o�n�е�x�s"�*�OZ����/uќ>t��a<�V	��Wsu{8�h�{�𢿉f]�|y��zz� �{���֣G�u�^�����n�Ǟ�����,d�2��M�@W�&]�Z?�o�{	m�4m��?@T���`	���||e~��h���`4�"�t��ɫ������f$��[�ۆ�X[d'O� ����M����>|�����������B���6�㿎
u�6.���.����_|���h�h=�G�"N�<t-?*�N�#��0-s���;���q��.�׽��9]z��GG~d<��ߌ9S��M�yM��}�Iѻ�V�C��>(�
7�#�7�B=�o�zh���о�#�{�7�DywqCW�C������M�Q�z��繣ڏ5�G��{�������6�w�\_6����~����`!`���gԟ���A�{a2�ˎ�?�k��M���ި��[�-��%�Q�8��E< @�o��'eU&-�R|y^x\e[�F�>Ʃ�K���1
=i��l'rt3�JLl�zm���F�X�jv�t��CR�t{��NǦ�.����=�P���>�{��u�g�~j����7χ}I��oғ���O��-H�U/تl�;��??��~��#�o�3�o`�w}���9����oE6��E�MP�'<���HaⰫ�ʡ,0,��4��a�lW�����p)�R�hYc+��Y.%����,M�cv(�R�'��YLc�Ь�uX����]���T��S<f�ZH�q�`�E[�vGJ�Q�F�9u4Ms	�;:#6�"�i>���]?���k��͈BWj�j�_%0#P?��{�����n(��m<��G`2��y�O�o����ď��������02���H���_�L��]�8���?9�c����'��������/R��ٽ�����?���Jv��~:�]�{ ���{�G�s���K��i���`uh����;���9���?[�}����k�]�𽞾'�?�-��p�?���,���	��a���}O�o�3���^��9�?�o+�K��	� �V��������s��[����3ǃE�-�^��0r���[� y����@��	�c���O�8���6d���c�- ;��������=k�#�oC���� �/{a������+d[
�-ٖ��mi�3���^����3٥�������S	���[������ɞ��`G����ߙ�������_��&�oG�K���O�Nw����$���o�o�?������A����^��@D��Q��k~���W�c��VoD����Q�aD�ѨR�w�t������������>��8k���oG.�����_b�щ����Ta�`���R(Iij2�^�p�pFd��_�nd$�&�j1}5:Wm���BH�^Ob�8L�$���X��F�w�f�;R�{�mD��THe�s�����/ϻ�wZ��������]�cN�}�}����۝���?v'���E��yfட��+������;y���"�rY�.10p�Tȥj���J�a�3,9rb��Qί�_hg�RFiw��A7�c�RR:88�������)%"�p?�P�I��᭩o���d���h;>0�iv��B9��ػ��D�n{���3�yZ���"����mr����Әt��ߛ�ߤ�N�%�\�j������V���s����\�}���~ŋ����������/����/������h�A���[�ǁ�ÁW��?��/�״�t[��h��a�75t�#E_N�U���~��e���&�����^n�Q�w�T�T5k��;M��(=�&�κ��޸�I��C�0�~a#%t8�N�u��%�Z,[u�ٍ�@�Cڕ�~ض�>����R��:���/��B����A�u\�z�������e
�P��z��e�Av�Efv}[��͖^+��荚�䣞i>��*�TW�t����aïX�Pa��T���\��j�8h��PN�eV�c!I��z~]�3�X���=�3vQ̚�A�f��Զ��5�s|6�_r~�?��$8���?#���@�,���M��?�����7�I�����.���GN����G���a�c��_����0��s�����H������_L���0�0��o�g��_,��/�!��_����>k��9�����$�?������a�a ����8�?�,��0��?|_������^�� ΟP�����<}�����A�Kw��@��������aM�����y�?K�����q W��l�}�9����s�8����?T��
���������	�?L ���,$������i�b������?���o���Ä��_2��6$?���������//��w�� �"��M�Ǚ�y��8��/�/����6�u�:I��teȽ�u�����%�p��eF�Ԟ������_��Oe*�TB=~�D�'���?n�֪��I]6��/�ҺV��f�2��f�3O�:AR��t�����&���&E֯���57��?SL���{u)�75 ԥ�j@ڙ����__&��c��r:OC\ը�F�%laRI����ӊ�LMH��mt�Z5����ٚ��I���'�/0��y�շ������3��?� w��!s���������O�aI��!��g�;���#�������?�\�4�������#��������C����s�����������p0�;'����1I�� �. ����	��1w�?r��8@��
/����PD>Rd�9�cC��D�c6dYZV��CIt
~�Ib��;��O>����A�s����<x��[m�w�E�[ׇO�ߨ���Z�ehǍѱx���Q*=~��U͠3t�p��+��Δ_�^c8���3�S��3�;�`�n��y%�Ja�V/���c����>*����,��Sq���e�3�����ߏk�I�����m�����O�~�8�znUq]�[��I���͋�������r]������������!w����g����� ����减�q��Of�eԴ☦��9��3�^u�FZ�YgX��l�:�'�'vJGa�v7l�e��ح�E��1�z_�����{�z�We����^�v\cׂ�ix>���v��X'�q�-�ppX�,���������� ���@�뿏~�ۯxe������� �_P��_P��?������H������	���E�E�_��1�c��ڷ�"[�g���Ы�X�_��{ ~������S!��:��<Jvh���!�P�Jq�f��9.v���J�Sl�,�j^���H�ң(v��d�5k�Oj��8�yUF�MS[�J����̣.:OCjVuu���Z�z6�4ǭ��eO01Tǭh�Uz�/��W40%���#�˲�J]�&�f�+�f���d����+ktFծ���J�bmv�o��hP[�S�w!=4�?�6����4�I5O��u�V���KR�8�&��Xc]���FG;��̌��F��K�ߝ'��6&����z��M�zu9cwȷn���`�l��Q����	��8@��g������_,���=���������/N%��8 �`�����_����'��}�DYfh.�Y�r���)B��d$���g]0��E,#�ad��®O���������a@���G��*UqL`UT=���Aч��^8��dK������A,���c��˖�j��T�@�� a�g��P�����=ݡȋX�������Z��q��g���_�f��q �Kޥ��!O
��?9RB�g��a^����Y��ЗxN	'y�/�t�)
h���,�����X��ǂ��e1
��(ݙ����hJ��Þ�ڠ�.�<�%�ᘝ������ƕ����?�+_�����
"�������g���^������/�����꿠�����K������w���a$��a�����6b~+����ϱ����A��c������������C�~����q����/t��$�?Kӷ���p��u��q��������M����	9��eLޗ�[��?w���_�� ���u�wޗ�[��?w�n���1� ��я�_���g��c�G�e��3������_άTR��S��)׼�D��B��)�@Hfn��_$sf��r��*]�R���z�I�Z�_t�8�4��G{)�î޷4�;X��Vv�>:Rþ0C{������o�X���VVGx��-m���^T��'�=FYU�g3�?ɁQϛ�\s`�=����������zER��!�v��/�E��I���ZY�ϓ�y�׎�r��L��b���4�n�qRgN�=1�r�HA�V�5�߮�59U*���l�}`�]��Da��Ъ�Y9z�~�.�.M�����������X�Р����)(ֽ>���K�ȓ_Ce�nFNd�t��=������YR���Mּ�w�������$��/S����G�U3*�����鑕RE^�´��B�d엇�zc�Lc��]AD�~�M۪���}���!�o�ftu�	-��t�_-F���7����� ��L�� ����[���������?��(���$��D���Ϥ�������q���������م㸨��@����¹���O]�et��S��n(����F�K�e]�cuu֞P���'fՉo[]?�g&kuM��5�����c��cT�y���?�ʠ��2�me��F_�)��6�)����
mD�S��J��f���Asc~�t�޺����tX�τT,O�~�[Ӫ�Ƽߓm7��Z��qg:,i$��,��L�q�-�x�hDY}��jK��\�:��ro�QY���xUg�j]�?��gf��*�US[nGh'i��P�vc�՗�x�	|5�[�T�)[�<B;K]�|YEet�Z�[2����*����^F'E�+��jT�ʦtV}7�)�Ҹ�QG���];�ו�#��,E�u�AϪ�==�xEڏm��~�ڮ��������_, @�=4��| ��{�?"�_�������,����� | ����������N�r�_�y���]��h�#���^�K����?����/c}���&*�%�o2 �C3����3 �ˁ0o� ��kO��SO�w� �� �`�Z�nE�����(��K�Ҩ�u��q���k�_e�co�&�5���EO���W\ď��b��[�]����#����� ��H��J��ӈR\�ޟM6Y��&Rg���)f����t��h��=�4j�W1`��	Y3��rVY��2=
\Z�a^2�ACR��]���n4뽩����oQc:,�p���^��W�< B�����?t���| ��{�?"��n ��! �$�8��p���p��W[�"�s'�ɀ����<8&�z��������#����_����$�g����@���%���PV���=�Wx�8F�1�}��}��R<FBHA</H0%�� �������9���ͬ����iQ��=�5��a�m����R�S��������v_J�nǖ;?UPI*�z���X� ����=:m�(T�����1�J���]�w�&��W�ewwl��]:X�5Y[%���V���C�������.��7W������D�?��������8���/�7	��/?|��k��%
i��U
�zL��F������6��YaZ�����
=��n0O;���>�f��n�s<]��N8�Д����P17Ew�Ӽm�8M���P7��Un596.���]y���&�`��{+�X�Y���	��>��o���@B����A��A������w�4` B����������|���������O��{\�_ڊ���If{Y��������U�]�]Yi#����}H���?7��<���By?W6"ߩc/��O��ަ?5���ow�{�hD}�n'|��L���S�lB.����1���.��Xgԭ��G�W�����֕.�ǭh����[-�+���Sg�E�Z,�d�Z-FQ+��}O+{2sJ��@;-#S�){��:����zr[,૖�̪t�܍R�&G�����c3E�}�Z�Q��픂ј���T3ۃ1Ǭ�Z��8�/��XQ�uWB!�m�y1\ł�q����
����N�?�Ƃ�_�a�+��q�_;����?8�`�/��8��<��]I�?����2�s^��殤��w�+�_� ���W��
�_s���M���1���/�����$�?�2���	��F�"����?�,��?��!������>O���R��{�?��~���0�(������������_�j��@��c�;��<�?����G������'���� ��Y�N�?���,�����7�9������?��!���\��ps��_1��c��<��eZ�1��O#!$�����k�NT����)j�=�t�tE3+����Κ�ˣD��͙��>U��&���6���������W{�
��f���d��R�DS���A��))#���~F������>�)��>���������ˋ^z8�����e���U��3��]����k��J����v^�Yhbs���3Ӛe��#һ+e��~�0�4�X�s߾i��8i5�u?Cr=��G�8��J�^��U��cF��� �y!���[���Ծ�����C�����#^8Q:���J�?~��0t
�O��|�=^�=
��m�I���x��iR��/�������7��<��c�� t(��9	y�cHf�1�US;���c:�@URrl6��L�̎i�N���2Y(�*DF���K C�������?C�����7���e��^�8�w�w�Rm��Z�k�͡���R�|���Z�.3n��3g�bi�L�=RU����Yd{�45K�KK�Õ2*v�z8��~۞%�O�9���tS�,�F>����Na����ǣ���%���t�����?������S�����c�?
��_�Y�?��M1���|�����r :2���<2������?�g�'���N ��/C�b�������~����@tB��z:�������������������9�1���A��?G��oC�b�����N�C������ǃ�I���Lq����}�@I�� z��]��ˏ�?�+���.7�P�J�Л�������{����h[�?��5�e��xͿo6K�{.ejU�8�����n�=/wJJ�]�J_gʣEΟ��s�����槄�\>kޕ�1�� �N�lg�����=���C����/�߄j�WB�~�-�lq;n<������w�v�<�*�N��)�B����z��L���9��jC���4_O�d��p:����sI���Y4b�(�?/���Q�9a=J�~�?�[W��0����b���������>~����(��o��$�?�'��� tZ��uh:���O���������������������#�[?vo�~�����w���G��������?������^]����+���osu�a���k5����[��h=��|�^�5n�������V�=��h�+���h̑w�IqU�r������=�/ʼ��[�~HeW�.wf��b1�݋��f2�oxg�IOe�\���uE�>!����D�׺�_���Z�L6�ej�ӦA�I#S^Ʊ�_e�X�V(�1L���֠�J�4�?J�����ȑe�/z�ʊo���U�[�[�%[�ч��4�f�b��^�%�:�Y���
W)HjG��5vĎ~>[�e��6ۙ#���_�v�|��1E���p��mI�s��Uo�xn��)��'���~kV*\���#�c�2�#�vu�W�w�y*e�ѰI�����u��H�W㬇f��8R�jbO(�Ʃ�2� jwrw��t�Krɉ9:g��4옃���-5���N������j,q!�e��c�qӯ����&�.�z������N��K�y�3���A��\;�e���?����m����Od!8�+��B����XN��8�R2�R�ٴ�d�d:��!	9+���U:CKV�hY!i%���-������t
�������?�����}uT��t�j&�z�p,'���s�Ŝ˝�K�4-�n�4�(D����Y�c.��d)�����Jo-,���(�Iud�nV��R1��ܤٱټ�h�����M����*/�ZZ+���^�%����V:��?>��xt���5�Eߣ�)����w<:	����8� ���&�x�����?���G���y����*���h��!�Q{���LoV�EŜ�FS%݁��m�?�Jgb_КI���k's�[ԯ�}��c��+��1�L#ۚCחV���/���ng0�3��4-�#+L�+�ұ��V:�����G���)����}��@���W���x���������_q�'�����m�c�I�,����ӱ�wz���#�O�<�����(p��7lu�O���>{�_����{Nݼ�_0�����_�@�a �m����LU��7�)��R%�&�W� p���bڽ
�<��]��LjF�F��h��|��/W��ɷ�½B�k�v��Vn8Q=g��kI����ύ��ֲ���kΧ�H�	m��c���	��������x��#��5��#��o�0Р$��Դ&��}>/gS��}��9�����M��4�:ӫ85AO l�&5�\(��1�)�����&��|����ĖP��b{�B2�z��
>VJ����r�$�����,�i����撰c5�k��p�;�j%f���Y_[��Tr��u�+wc��k��XKs��2^���P��O������	�bm���e����Ep��8�mȅ� >�@������
4xQV���cڗ�[H�^P	�C/ޏ����B;05�3p�p��:68�5ֶ�)i�����`Z*t޹J[��$ x_�_T�� ui/�J  o�%ݼ[v[���ec�g�T�Q�@��� �Ɩ0�Ѕ [�AhX?�6AU.���cJ��A�D�����i[�"�|��j�ހ���>u;>Z|?��D��#`�Dw��@@\@S���!�Ӆ�+��Td[�&H~��`myv�/��=;�� 5�x����}	e�$Ѕ��$~�1��	�P�$H�-�q�8�˵u� �"��ָlG�UBY]�h�0�H�>=�8 ��ᝧ�P�
��@��E�(��p$���j0�->�3�e�K#����OP�cn�<$,�=h!���U����.�g�:j��.y��-}���N������3�i���	tJ���g?d�Ot�ǖ좼�|ԷK��PǶ5*�������'�BQ�߀��%4։�-�}:�c�Bi�<c�Pʳp��VS�G�X�;��e���Pԅ,9H�
�|�$��[%Y�_H��8p�h���2�,�	&�@�v $�Ucn�0�w"�.B��Q�T�ew6�$�XG��t �\K˚����3<���z>Eb�,�t/R�Z��֏z�kizsM����L�}������J�T�
|����������G�bhrmOqC�XU�l��kbG���l��!��r��s=�!T�s�!�ش#�`d˝D�"HwN�t	��Pü���,?v:+��iWB}��r}��_Py�2��l?Hr�;�a���i7��K�~HxT�nM����w������w�#��S���>N��>��H(�[��(��n�l,�j�a�X��#n>�FAs��+N�O���w-��5�����'����g2L����p�M���6��(�s���!��d�.(p|�,�
��m�떮>7y"��0���m�ud�
��D�f��Bpay��sy�Rf � _Zx?!�?�(L$ӄƆ��e��]m3U�D$�`���Q��qG������:����4��C᷄I�Si�M���#���K��A`��!{b�}.ihR���6��!��DF�.?sm���92�����m���c�e�m�Q���U�{�E2������m���!{*K|��S8_(W�P�f���S�~\PE�\9E�ҘNgdJ��4�����!�g2cE��ʎS�D�4�?G��X�2�d�De�[gF�qz+�uƒi��	"f@�%p&�O���x6������?:�?�9��c��Ir&-ɲL2Y�U%5EAF!��$I���,��d!-�*>SX�QOfs�aaJ�Hu��Ap��e�w����7�����Vw%~~�[���omM4&��}����e����5���{2����oS�F;/��Tź�檷�F�*���
eO{9[���\>�;�+2��bn�o�ܩ��R#�%䵬��kc9�dY��(���:�r�*�X�ū�����*��-�ƿ&�eϐ�z���%HZ7�Yɝ$[Ijȩ��@���ծ�Z[��'��T��zN��P���馻v��j���汥��ep�{�w��R��*}��B��}�WD?�6ymy�\GV�(��zp_(q���?�u"/��n�~�V�盍r�{���2�L�8Kr)�I�3#�*�l�g�$.�I���w�m/�&��Գ��B=Zjt�B�^(o�bw�hWj�uW5��v�w�Q-��7��Pj�=p�I����<��/�g;]�+��\�㹎x��\e���_h�R���]m:H����e:�e�UA�m�Q�r�r9t�j,|A�S���.h�B���Bt�+S]��ጟ��>�_,7X��+����
�T�[d�>t�K3%����t쟭�|?������dı�=
�8��vẨ;�h�<��C�9��[\�sc����P�U�7�̈́3��2^���J���T�"i&�������w��oIY7���L�k�
/��`�ێ�m[�7��u��al��Ix��.�3y�B�(��lH`Y���D�/������$�nųm��� ��u������/@Q��	�<��'���m��k�����|=�X�*���v&b�3��&�GM}\�p֎�<:.�}PП���g�aX�@M�n�\�����0=�̛2�*���pn-�E�@����BⓍ����/�x�O�f���04����&)h�a7��p��I�}��`�Q��V4D/�~Atm�u����M������+f4�<{ӥ���9(���2��OMo�ǵ����^���f���3,B���Si����t��� Xʞ�9��0� ��&��eNx�}Op`�9aX|s�?X\�������?2���dP��Ql��� ���G��C�uŅ��B��	Tf��D
� W�{d�m-Y��\��C�c0A�|���$���`n��1o_\l�/���($�"._>S��ޕ������-R�
0=�6U��V�ڗ(�ꆫ"E��ޙ��6��5��ޝ��szv���{���x�j�Q _���A�!�pr1���:U�M����K�`J�䆚e��uH-6�~��:���ZYG�If ]��z\2�n�8jw7�{_��H�h>߅���	ES<c\���gFj3����>��!4
����P�X|�^�߿�gp����%Mr�e1���")��O@*#���c蝋Ijo\&bY�\�c	8vσBPL�O	5���|�m&��@Z�F�W%�x�1�T�#��ӿԀ��K�e���)���=���ژ�_+��%�D|����+�o�r���I8[-�cYb#�3�|eU�����T��S���m����v���t<��^7n��n�	����8�����}���]�u[�|Q]�^�^D��~�J���N�2��Rs�B=�t\�i.5w�����t4�C�2�Ƽ�Bc�Ѡ ��ć:�qMor]��c0��}C��h�-�N��-΢�j"�k*��e=@�ɲnioH�WE	M��pj�R�~&G�����%�5f�@���i�U���n����BW���������+<&�u��t�v�+��o�Dt�r���A_�v���?� c$&��.��
�"���4 ��D�h����dk`�V�ze��r&�
��w{_E�h�+�F���X�1���5u9mʟ�}8�N�4^�˘�Q�&1�gN� ?K�� ���tz��g&��`0��`0��`0��� �r�b 0 